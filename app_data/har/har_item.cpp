#include "har_item.h"

HarItem HarItem::fromJson(const QJsonObject& json) noexcept
{
    HarItem item;
    item.name = json.value("name").toString();
    item.value = json.value("value").toString();

    return item;
}