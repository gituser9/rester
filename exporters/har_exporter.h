#ifndef HAR_EXPORTER_H
#define HAR_EXPORTER_H

#include <QSharedPointer>
#include <QString>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDateTime>
#include <QUrl>
#include <QUrlQuery>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

class HarExporter
{
public:
    static QString exportWorkspace(QSharedPointer<Workspace> workspace);

private:
    static void collectQueries(TreeNode* node, QList<Query*>& list);
    static QJsonObject buildEntry(Query* query);
    static QJsonObject buildRequest(Query* query);
    static QJsonArray queryParamsToArray(const QList<QueryParam>& params);
    static QJsonObject buildPostData(Query* query);
    static QJsonObject buildResponse();
    static QJsonObject buildCache();
    static QJsonObject buildTimings();
};

#endif // HAR_EXPORTER_H
