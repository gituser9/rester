#include "graphql_parser.h"

ParseResult GraphqlParser::parse(const QString& graphqlQuery, const QList<QueryParam>& variables)
{
    ParseResult result;
    QString trimmedQuery = graphqlQuery.trimmed();

    if (trimmedQuery.isEmpty()) {
        result.errorString = "GraphQL query is empty";
        return result;
    }

    result.operationName = extractOperationName(trimmedQuery);

    QJsonObject payload;
    payload["query"] = trimmedQuery;

    if (result.operationName.has_value()) {
        payload["operationName"] = result.operationName.value();
    }

    if (!variables.isEmpty()) {
        QJsonObject vars;

        for (const QueryParam& var : variables) {
            if (!var.isEnabled()) {
                continue;
            }

            vars[var.name()] = var.value(); // TODO: types
        }

        payload["variables"] = vars;
    }

    result.requestPayload = QJsonDocument(payload).toJson(QJsonDocument::Compact);
    result.isValid = true;

    return result;
}

QString GraphqlParser::buildCurl(const GraphqlQuery* qry, const QVariantMap& vars)
{
    auto parseResult = parse(qry->body(), qry->variablesList());

    if (!parseResult.isValid) {
        return "";
    }

    QString currentEnv = vars.value("env", "").toString();
    QVariantList envVars = vars.value(currentEnv).toList();

    QString url = "  --url '" + CurlUtils::buildUrl(qry->url(), envVars) + "' \\" + "\n";
    QString method = QString(" --request POST") + " \\" + "\n";
    QString headers = CurlUtils::buildHeaders(qry->headerList(), envVars);
    headers += QString("  --header 'Content-Type: application/json'") + " \\" + "\n";
    QString body = "  --data '" + parseResult.requestPayload + "' \\" + "\n";
    QString curlCommand = "curl" + method + url + headers + body;

    qsizetype pos = curlCommand.lastIndexOf("\\");

    if (pos != -1) {
        curlCommand = curlCommand.left(pos);
    }

    return curlCommand + "\n";
}

std::optional<QString> GraphqlParser::extractOperationName(const QString& query)
{
    static const QRegularExpression operationRegex(
        R"((?:query|mutation|subscription)\s+([a-zA-Z_][a-zA-Z0-9_]*))");

    QRegularExpressionMatch match = operationRegex.match(query);

    if (match.hasMatch()) {
        return match.captured(1);
    }

    return std::nullopt;
}
