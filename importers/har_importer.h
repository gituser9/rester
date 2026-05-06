#ifndef HAR_IMPORTER_H
#define HAR_IMPORTER_H

#include <memory>

#include <QByteArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>
#include <QMap>
#include <QString>
#include <QFile>
#include <QUrl>
#include <QUrlQuery>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

class HarImporter
{
public:
    std::shared_ptr<Workspace> importWorkspace(const QString& path);

private:
    QByteArray getJson(const QString& path);
    BodyType detectBodyType(const QString& mimeType);
};

#endif // HAR_IMPORTER_H
