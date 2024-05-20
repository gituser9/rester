#include "importer.h"

using namespace std;

Importer::Importer(QObject* parent) : QObject { parent }
{
}

QList<shared_ptr<Workspace>> Importer::import(const QString& filePath, ImportType type) noexcept
{
    switch (type) {
    case ImportType::Rester:
        return fromRester(filePath);
    default:
        return fromExternal(filePath, type);
    }
}

void Importer::exportWorkspaces(const QString& folderPath, const QString& exportPath) const noexcept
{
    QString copyPath = exportPath + "/workspaces/";
    QDir wsDir(folderPath);

    QDir exportDir;
    exportDir.mkpath(copyPath);

    for (const QString& fileName : wsDir.entryList()) {
        QString path = folderPath + fileName;
        QFile file(path);

        file.copy(copyPath + fileName);
    }
}

void Importer::exportCollection(QSharedPointer<Workspace> workspace, const QString& exportPath, ImportType type)
{
    QJsonObject json;

    switch (type) {
    case ImportType::Insomnia:
        json = toInsomniaCollection(workspace)->toJson();
        break;
    case ImportType::Postman:
        json = toPostmanCollection(workspace)->toJson();
        break;
    case ImportType::Rester:
        json = workspace->toJson();
        break;
    default:
        break;
    }

    if (json.isEmpty()) {
        return;
    }

    QString dateString = QDateTime::currentDateTime().toString("dd_MM_yyyy");
    QString fileName = workspace->name() + "_" + dateString + "_";

    switch (type) {
    case ImportType::Insomnia:
        fileName += "Insomnia.json";
        break;
    case ImportType::Postman:
        fileName += "Postman.json";
        break;
    case ImportType::Rester:
        fileName += "Rester.json";
        break;
    default:
        break;
    }

    Util::writeJsonToFile(exportPath + "/" + fileName, json);
}

QList<shared_ptr<Workspace>> Importer::fromRester(const QString& folderPath) const noexcept
{
    QDir wsDir(folderPath);
    QStringList files = wsDir.entryList();

    QList<shared_ptr<Workspace>> workspaces;
    workspaces.reserve(files.count());

    for (const QString& fileName : files) {
        QString path = folderPath + fileName;
        QJsonObject json = Util::getJsonFromFile(path);

        if (json.isEmpty()) {
            continue;
        }

        auto workspace = make_shared<Workspace>();
        workspace->fromJson(json);

        workspaces << workspace;
    }

    return workspaces;
}

QList<shared_ptr<Workspace>> Importer::fromExternal(const QString& filePath, ImportType type) noexcept
{
    auto workspaceJson = QString(Import(filePath.toStdString().c_str(), GoInt(type)));
    QList<shared_ptr<Workspace>> workspaces;

    if (workspaceJson.isEmpty() || workspaceJson == "{}") {
        return workspaces;
    }

    // parse in json object
    QJsonParseError jsonError;
    QJsonDocument jsonDocument = QJsonDocument::fromJson(workspaceJson.toUtf8(), &jsonError);

    if (jsonError.error != QJsonParseError::NoError) {
        emit error("Parse file error: " + jsonError.errorString());

        return workspaces;
    }

    QJsonArray items = jsonDocument.array();
    workspaces.reserve(items.count());

    for (QJsonValueRef&& item : items) {
        auto ws = make_shared<Workspace>();
        ws->fromJson(item.toObject());

        workspaces << ws;
    }

    return workspaces;
}

QSharedPointer<Insomnia> Importer::toInsomniaCollection(QSharedPointer<Workspace> ws) const noexcept
{
    auto insomnia = QSharedPointer<Insomnia>(new Insomnia);
    insomnia->type = "export";
    insomnia->exportFormat = 4;
    insomnia->exportDate = QDateTime::currentDateTime().toString("yyyy-MM-ddTHH:mm:ss.zzzZ");
    insomnia->exportSource = "rester";

    InsomniaResource wsResource = ws->toInsomniaResource();
    QList<InsomniaResource> resources = { wsResource };

    for (TreeNode* node : ws->nodes()) {
        if (node->nodeType() == NodeType::FolderNode) {
            auto fld = static_cast<Folder*>(node);
            resources << fld->toInsomniaResource(wsResource.id, nullptr);

            continue;
        }

        if (node->nodeType() == NodeType::QueryNode) {
            auto qry = static_cast<Query*>(node);
            resources << qry->toInsomniaResource(wsResource.id);

            continue;
        }
    }

    insomnia->resources = resources;

    return insomnia;
}

QSharedPointer<PostmanCollection> Importer::toPostmanCollection(QSharedPointer<Workspace> ws) const noexcept
{
    auto postman = QSharedPointer<PostmanCollection>(new PostmanCollection);
    postman->info.name = ws->name();
    postman->info.postId = Util::uuid();
    postman->info.schema = "https://schema.getpostman.com/json/collection/v2.1.0/collection.json";
    // postman->info.e = 9895154

    for (TreeNode* node : ws->nodes()) {
        if (node->nodeType() == NodeType::FolderNode) {
            auto fld = static_cast<Folder*>(node);
            postman->items << fld->toPostmanItem(nullptr);

            continue;
        }

        if (node->nodeType() == NodeType::QueryNode) {
            auto qry = static_cast<Query*>(node);
            postman->items << qry->toPostmanItem();

            continue;
        }
    }

    return postman;
}
