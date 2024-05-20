#ifndef POSTMAN_REQUEST_BODY_H
#define POSTMAN_REQUEST_BODY_H

#include <QJsonArray>
#include <QJsonObject>

#include "postman_options.h"

class PostmanFormDataBody {
public:
    QString key;
    QString value;
    QString type;
};

class PostmanRequestBody {
public:
    QString mode;
    QString raw;
    PostmanOptions options;
    QList<PostmanFormDataBody> formdata;

    QJsonObject toJson() const;
};

#endif