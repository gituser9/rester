#include "postman_request.h"

PostmanRequest PostmanRequest::fromJson(const QJsonObject& json)
{
    PostmanRequest request;
    request.method = json["method"].toString();

    QJsonArray headersArray = json["headers"].toArray();

    for (QJsonValue&& headerValue : headersArray) {
        QJsonObject headerObject = headerValue.toObject();
        request.headers << PostmanHeader::fromJson(headerObject);
    }

    request.url = PostmanUrl::fromJson(json["url"].toObject());
    return request;
}

QJsonObject PostmanRequest::toJson() const noexcept
{
    QJsonArray headersArray;

    for (const PostmanHeader& header : headers) {
        headersArray << header.toJson();
    }

    QJsonObject requestObject = {
        { "method", method },
        { "headers", headersArray },
        { "url", url.toJson() },
    };

    if (!body.mode.isEmpty()) {
        requestObject["body"] = body.toJson();
    }

    return requestObject;
}