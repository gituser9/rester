#ifndef __HAR_ITEM_H__
#define __HAR_ITEM_H__

#include <QJsonObject>
#include <QString>

struct HarItem {
    QString name;
    QString value;

    static HarItem fromJson(const QJsonObject& json) noexcept;
};

#endif // __HAR_ITEM_H__