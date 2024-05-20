#ifndef POSTMAN_URL_H
#define POSTMAN_URL_H

#include <QString>
#include <QStringList>
#include <QJsonObject>
#include <QJsonArray>


class PostmanUrl {
public:
    QString raw;
    QString protocol;
    QStringList host;
    QStringList path;
    QVariantList query;

    static PostmanUrl fromJson(const QJsonObject &json);
    QJsonObject toJson() const noexcept;
};

#endif // POSTMAN_URL_H
