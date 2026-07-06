#ifndef POSTMAN_EXPORTER_H
#define POSTMAN_EXPORTER_H

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSharedPointer>
#include <QString>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

class PostmanExporter
{
public:
    // Экспортирует Workspace в JSON-строку формата Postman Collection v2.1
    static QString exportWorkspace(QSharedPointer<Workspace> workspace);

private:
    // Рекурсивно строит элемент коллекции (папку или запрос)
    static QJsonObject buildItem(TreeNode* node);

    // Создаёт объект запроса Postman
    static QJsonObject buildRequest(Query* query);

    // Строит объект URL (raw + query)
    static QJsonObject buildUrl(const QString& rawUrl, const QList<QueryParam>& params);

    // Строит объект body в зависимости от типа тела
    static QJsonObject buildBody(RstEnums::BodyType type, const QString& bodyText);

    // Преобразует QMap в массив {key, value}
    static QJsonArray mapToKeyValueArray(const QList<QueryParam>& map);
};

#endif // POSTMAN_EXPORTER_H
