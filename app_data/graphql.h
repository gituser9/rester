#ifndef RESTER_GRAPHQL_H
#define RESTER_GRAPHQL_H

#include <optional>

#include <QString>
#include <QByteArray>
#include <QJsonObject>

struct ParseResult {
    QByteArray requestPayload;
    std::optional<QString> operationName;
    bool isValid = false;
    QString errorString;
};

#endif // RESTER_GRAPHQL_H
