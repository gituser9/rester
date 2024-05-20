#ifndef POSTMAN_REQUEST_H
#define POSTMAN_REQUEST_H

#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QString>

#include "postman_header.h"
#include "postman_request_body.h"
#include "postman_url.h"

class PostmanRequest {
public:
    QString method;
    QList<PostmanHeader> headers;
    PostmanUrl url;
    PostmanRequestBody body;

    static PostmanRequest fromJson(const QJsonObject& json);
    QJsonObject toJson() const noexcept;
};

#endif