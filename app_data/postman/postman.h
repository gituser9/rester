#ifndef POSTMAN_H
#define POSTMAN_H

#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QStringList>
#include <QUuid>

#include "postman_item.h"

struct Info {
    QString postId;
    QString name;
    QString description;
    QString schema;
};

class PostmanCollection {
public:
    Info info;
    QList<PostmanItem> items;

    static PostmanCollection fromJson(const QJsonObject& json);

    QJsonObject toJson() const noexcept;
};

#endif // POSTMAN_H
