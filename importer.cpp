#include "importer.h"

using namespace std;

Importer::Importer(QObject* parent) : QObject{parent}
{
}

shared_ptr<Workspace> Importer::importWorkspace(const QString& filePath, ImportType type) noexcept
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

shared_ptr<Workspace> Importer::fromRester(const QString& filePath) const noexcept
{

    QJsonObject json = Util::getJsonFromFile(filePath);

    if (json.isEmpty()) {
        return nullptr;
    }

    auto workspace = std::make_shared<Workspace>();
    workspace->fromJson(json);

    return workspace;
}

shared_ptr<Workspace> Importer::fromExternal(const QString& filePath, ImportType type) noexcept
{
    if (type == ImportType::InsomniaV5) {
        auto importer = std::make_unique<InsomniaV5Importer>();

        return importer->importWorkspace(filePath);
    }

    if (type == ImportType::Swagger) {
        auto importer = std::make_unique<SwaggerImporter>();

        return importer->importWorkspace(filePath);
    }

    if (type == ImportType::Postman) {
        auto importer = std::make_unique<PostmanImporter>();

        return importer->importWorkspace(filePath);
    }

    if (type == ImportType::Har) {
        auto importer = std::make_unique<HarImporter>();

        return importer->importWorkspace(filePath);
    }

    return {};
}
