#ifndef POSTMANHEADER_H
#define POSTMANHEADER_H

#include <QJsonObject>
#include <QString>

class PostmanHeader {
public:
    QString key;
    QString value;

    static PostmanHeader fromJson(const QJsonObject& json);
    QJsonObject toJson() const noexcept;
};

#endif