#include "postman_item.h"

PostmanItem PostmanItem::fromJson(const QJsonObject& json)
{
    PostmanItem item;
    item.name = json["name"].toString();
    item.request = PostmanRequest::fromJson(json["request"].toObject());

    return item;
}

QJsonObject PostmanItem::toJson() const noexcept
{
    QJsonObject itemObject;
    itemObject["name"] = name;

    if (!request.url.raw.isEmpty()) {
        itemObject["request"] = request.toJson();
    }

    QJsonArray itemsArray;

    if (!items.isEmpty()) {
        for (const PostmanItem& item : items) {
            itemsArray << item.toJson();
        }
    }

    if (!itemsArray.isEmpty()) {
        itemObject["item"] = itemsArray;
    }

    return itemObject;
}