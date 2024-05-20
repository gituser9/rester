#include "postman_url.h"

PostmanUrl PostmanUrl::fromJson(const QJsonObject& json)
{
    PostmanUrl url;
    url.raw = json["raw"].toString();
    url.protocol = json["protocol"].toString();
    url.host = json["host"].toString().split(".");
    url.path = json["path"].toString().split("/");

    return url;
}
QJsonObject PostmanUrl::toJson() const noexcept
{
    QJsonObject urlObject = {
        { "raw", raw },
        { "protocol", protocol },
    };

    QJsonArray hostArray;

    for (const QString& hostItem : host) {
        hostArray << hostItem;
    }

    urlObject["host"] = hostArray;

    QJsonArray pathArray;

    for (const QString& pathItem : path) {
        if (pathItem.isEmpty()) {
            continue;
        }

        pathArray << pathItem;
    }

    if (!pathArray.isEmpty()) {
        urlObject["path"] = pathArray;
    }

    if (!query.isEmpty()) {
        urlObject["query"] = QJsonArray::fromVariantList(query);
    }

    return urlObject;
}
