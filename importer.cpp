#include "importer.h"

using namespace std;

Importer::Importer(QObject* parent) : QObject{parent}
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
    QString dateString = QDateTime::currentDateTime().toString("dd_MM_yyyy");
    QString fileName = workspace->name() + "_" + dateString + "_";

    switch (type) {
    case ImportType::InsomniaV5:
        fileName += "Insomnia_v5.yaml";
        break;
    case ImportType::Postman:
        fileName += "Postman.json";
        break;
    case ImportType::Rester:
        fileName += "Rester.json";
        break;
    case ImportType::Har:
        fileName += "HAR.har";
        break;
    default:
        break;
    }

    QString json;
    QString filePath = exportPath + "/" + fileName;

    switch (type) {
    case ImportType::Postman:
        json = PostmanExporter::exportWorkspace(workspace);
        break;
    case ImportType::Rester:
        json = QJsonDocument(workspace->toJson()).toJson();
        break;
    case ImportType::InsomniaV5:
        json = InsomniaV5Exporter::exportWorkspace(workspace);
        break;
    case ImportType::Har:
        json = HarExporter::exportWorkspace(workspace);
        break;
    default:
        break;
    }

    if (json.isEmpty()) {
        return;
    }

    Util::writeToFile(exportPath + "/" + fileName, json);
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

        auto workspace = std::make_shared<Workspace>();
        workspace->fromJson(json);

        workspaces << workspace;
    }

    return workspaces;
}

QList<shared_ptr<Workspace>> Importer::fromExternal(const QString& filePath, ImportType type) noexcept
{
    if (type == ImportType::InsomniaV5) {
        auto importer = std::make_unique<InsomniaV5Importer>();

        return {importer->import(filePath)};
    }

    if (type == ImportType::Swagger) {
        auto importer = std::make_unique<SwaggerImporter>();

        return {importer->import(filePath)};
    }

    if (type == ImportType::Postman) {
        auto importer = std::make_unique<PostmanImporter>();

        return {importer->import(filePath)};
    }

    if (type == ImportType::Har) {
        auto importer = std::make_unique<HarImporter>();

        return {importer->import(filePath)};
    }

    return {};
}
