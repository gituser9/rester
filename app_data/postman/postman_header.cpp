#include "postman_header.h"

PostmanHeader PostmanHeader::fromJson(const QJsonObject& json)
{
    PostmanHeader header;
    header.key = json["key"].toString();
    header.value = json["value"].toString();

    return header;
}

QJsonObject PostmanHeader::toJson() const noexcept
{
    return {
        { "key", key },
        { "value", value }
    };
}