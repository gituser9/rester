#ifndef REST_CLIENT_POSTMAN_OPTIONS_H
#define REST_CLIENT_POSTMAN_OPTIONS_H

#include <QJsonObject>

class PostmanOptions {
public:
    QString language;

    QJsonObject toJson() const;
};

#endif // REST_CLIENT_POSTMAN_OPTIONS_H
