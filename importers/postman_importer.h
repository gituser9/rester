#ifndef POSTMAN_IMPORTER_H
#define POSTMAN_IMPORTER_H

#include <QByteArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>
#include <QMap>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

class PostmanImporter
{
public:
    std::shared_ptr<Workspace> importWorkspace(const QString& path);

private:
    void parseItem(const QJsonObject& itemObj, TreeNode* parent, const QJsonObject& parentAuth);
    void setAuth(const QJsonObject& authObj, Query* query);
    QByteArray getJson(const QString& path);
    void setBody(const QJsonObject& reqObj, Query* query);
};

#endif // POSTMAN_IMPORTER_H
