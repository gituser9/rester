#include "postman_options.h"

QJsonObject PostmanOptions::toJson() const
{
    return { { "language", language } };
}
