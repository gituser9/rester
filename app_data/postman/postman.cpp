#include "postman.h"


PostmanCollection PostmanCollection::fromJson(const QJsonObject &json)
{
    PostmanCollection collection;
    collection.info.postId = json["info"]["_postman_id"].toString();
    collection.info.name = json["info"]["name"].toString();
    collection.info.description = json["info"]["description"].toString();
    collection.info.schema = json["info"]["schema"].toString();

    QJsonArray itemsArray = json["item"].toArray();

    for (QJsonValue&& itemValue : itemsArray) {
        collection.items.append(PostmanItem::fromJson(itemValue.toObject()));
    }

    return collection;
}

QJsonObject PostmanCollection::toJson() const noexcept {
    QJsonObject collectionObject;
    QJsonObject infoObject = {
        {"_postman_id", info.postId},
        {"name", info.name},
        {"description", info.description},
        {"schema", info.schema},
    };
    collectionObject["info"] = infoObject;

    QJsonArray itemsArray;

    for (const PostmanItem &item : items) {
        itemsArray << item.toJson();
    }

    collectionObject["item"] = itemsArray;

    return collectionObject;
}
