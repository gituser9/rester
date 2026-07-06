#include "har_exporter.h"

QString HarExporter::exportWorkspace(QSharedPointer<Workspace> workspace)
{
    if (!workspace) {
        return {};
    }

    QList<Query*> queries;
    const auto rootNodes = workspace->nodes();

    for (TreeNode* node : rootNodes) {
        collectQueries(node, queries);
    }

    QJsonArray entries;
    for (Query* query : queries) {
        entries.append(buildEntry(query));
    }

    QJsonObject log;
    log["version"] = "1.2";

    QJsonObject creator;
    creator["name"] = "AppName";
    creator["version"] = "1.0";
    log["creator"] = creator;
    log["entries"] = entries;

    QJsonObject har;
    har["log"] = log;

    QJsonDocument doc(har);

    return QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
}

void HarExporter::collectQueries(TreeNode* node, QList<Query*>& list)
{
    if (!node) {
        return;
    }

    if (node->nodeType() == RstEnums::NodeType::QueryNode) {
        list.append(static_cast<Query*>(node));
    }
    else if (node->nodeType() == RstEnums::NodeType::FolderNode) {
        auto folder = static_cast<Folder*>(node);
        const auto children = folder->nodes();

        for (TreeNode* child : children) {
            collectQueries(child, list);
        }
    }
}

QJsonObject HarExporter::buildEntry(Query* query)
{
    QJsonObject entry;
    entry["startedDateTime"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    entry["time"] = 0;
    entry["request"] = buildRequest(query);
    entry["response"] = buildResponse();
    entry["cache"] = buildCache();
    entry["timings"] = buildTimings();

    return entry;
}

QJsonObject HarExporter::buildRequest(Query* query)
{
    QJsonObject request;
    request["method"] = Util::getQueryTypeString(query->queryType());
    request["url"] = query->url();
    request["httpVersion"] = "HTTP/1.1";
    request["headersSize"] = -1;
    request["bodySize"] = -1;
    request["headers"] = queryParamsToArray(query->headerList());
    request["queryString"] = queryParamsToArray(query->paramList());
    request["cookies"] = QJsonArray();

    QJsonObject postData = buildPostData(query);
    request["postData"] = buildPostData(query);

    return request;
}

QJsonArray HarExporter::queryParamsToArray(const QList<QueryParam>& params)
{
    QJsonArray arr;

    for (const QueryParam& param : params) {
        QJsonObject p;
        p["name"] = param.name();
        p["value"] = param.value();

        arr.append(p);
    }

    return arr;
}

QJsonObject HarExporter::buildPostData(Query* query)
{
    QJsonObject postData;
    RstEnums::BodyType type = query->bodyType();

    if (type == RstEnums::BodyType::NONE) {
        return postData;
    }

    QString mimeType;

    switch (type) {
    case RstEnums::BodyType::JSON:
        mimeType = "application/json";
        break;
    case RstEnums::BodyType::XML:
        mimeType = "application/xml";
        break;
    case RstEnums::BodyType::URL_ENCODED_FORM:
        mimeType = "application/x-www-form-urlencoded";
        break;
    case RstEnums::BodyType::MULTIPART_FORM:
        mimeType = "multipart/form-data";
        break;
    default:
        mimeType = "text/plain";
    }

    postData["mimeType"] = mimeType;

    if (type == RstEnums::BodyType::JSON || type == RstEnums::BodyType::XML) {
        postData["text"] = query->body().isEmpty() ? QString() : query->body();
    }
    else if (type == RstEnums::BodyType::MULTIPART_FORM) {
        QJsonArray paramsArr;

        for (const QueryParam& item : query->formDataList()) {
            QJsonObject param;
            param["name"] = item.name();
            param["value"] = item.value();

            paramsArr.append(param);
        }

        postData["params"] = paramsArr;
    }
    else if (type == RstEnums::BodyType::URL_ENCODED_FORM && !query->body().isEmpty()) {
        QJsonArray paramsArr;

        QUrlQuery urlQuery;
        urlQuery.setQuery(query->body());
        const auto items = urlQuery.queryItems();

        for (const auto& item : items) {
            QJsonObject param;
            param["name"] = item.first;
            param["value"] = item.second;

            paramsArr.append(param);
        }

        if (!paramsArr.isEmpty()) {
            postData["params"] = paramsArr;
        }
    }

    return postData;
}

QJsonObject HarExporter::buildResponse()
{
    QJsonObject response;
    response["status"] = 0;
    response["statusText"] = "";
    response["httpVersion"] = "HTTP/1.1";
    response["headers"] = QJsonArray();
    response["cookies"] = QJsonArray();
    response["content"] = QJsonObject{
        {"size", 0},
        {"mimeType", "text/plain"},
        {"text", ""}};
    response["redirectURL"] = "";
    response["headersSize"] = -1;
    response["bodySize"] = -1;
    return response;
}

QJsonObject HarExporter::buildCache()
{
    QJsonObject cache;
    cache["beforeRequest"] = QJsonValue::Null;
    cache["afterRequest"] = QJsonValue::Null;

    return cache;
}

QJsonObject HarExporter::buildTimings()
{
    QJsonObject timings;
    timings["blocked"] = -1;
    timings["dns"] = -1;
    timings["connect"] = -1;
    timings["send"] = 0;
    timings["wait"] = 0;
    timings["receive"] = 0;
    timings["ssl"] = -1;

    return timings;
}
