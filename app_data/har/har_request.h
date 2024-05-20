#ifndef HAR_REQUEST_H
#define HAR_REQUEST_H

#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QMap>
#include <QString>
#include <QUrl>
#include <QVariantMap>

#include "../../util.h"
#include "../query.h"
#include "har_item.h"
#include "har_post_data.h"

class HarRequest {
public:
    QString method;
    QString url;
    HarPostData postData;
    QList<HarItem> headers;
    QList<HarItem> queryString;

    static HarRequest fromJson(QJsonObject&& json) noexcept;
    Query* toQuery() noexcept;

private:
    QMap<QString, QString> parseDataRaw(const QString& dataRaw) noexcept;
};

#endif