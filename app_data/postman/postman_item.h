#ifndef POSTMAN_ITEM_H
#define POSTMAN_ITEM_H

#include "postman_request.h"

class PostmanItem {
public:
    QString name;
    PostmanRequest request;
    QList<PostmanItem> items;

    static PostmanItem fromJson(const QJsonObject& json);
    QJsonObject toJson() const noexcept;
};

#endif