#ifndef SWAGGER_IMPORTER_H
#define SWAGGER_IMPORTER_H

#include <memory>

#include <QByteArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QMap>
#include <QString>
#include <QFile>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

struct SecurityScheme {
    QString type;
    QString name;   // header name (for apiKey)
    QString in;     // where (header, query, cookie)
    QString scheme; // bearer, basic etc.
};

class SwaggerImporter
{
public:
    std::shared_ptr<Workspace> importWorkspace(const QString& path);

private:
    QMap<QString, SecurityScheme> _securitySchemes;
    QJsonArray _globalSecurity;

    QString extractBaseUrl(const QJsonObject& root);
    BodyType detectBodyType(const QJsonObject& operation);
    QByteArray getJson(const QString& path);
    void setSecurity(const QJsonObject& root, const QJsonObject& operation, Query* query);
    void setParams(const QJsonObject& operation, Query* query);
    QMap<QString, SecurityScheme> extractSecurity(const QJsonObject& root);
};

#endif // SWAGGER_IMPORTER_H
