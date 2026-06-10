#ifndef GRAPHQL_PARSER_H
#define GRAPHQL_PARSER_H

#include <QMap>
#include <QList>
#include <QRegularExpression>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonValue>
#include <QJsonObject>

#include "../app_data/graphql.h"
#include "../app_data/graphql_query.h"
#include "../app_data/query_param.h"
#include "../app_data/workspace.h"
#include "curl_utils.h"

class GraphqlParser
{
public:
    static ParseResult parse(
        const QString& graphqlQuery,
        const QList<QueryParam>& variables = {} //
    );
    static QString buildCurl(const GraphqlQuery* qry, const QVariantMap& vars);

private:
    static std::optional<QString> extractOperationName(const QString& query);
};

#endif // GRAPHQL_PARSER_H
