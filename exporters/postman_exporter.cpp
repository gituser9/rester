#include "postman_exporter.h"

#include <QUrl>
#include <QUrlQuery>

QString PostmanExporter::exportWorkspace(QSharedPointer<Workspace> workspace)
{
    if (!workspace) {
        return QString();
    }

    QJsonObject collection;
    QJsonObject info;
    info["name"] = workspace->name();
    info["_postman_id"] = workspace->uuid();
    info["schema"] = QStringLiteral("https://schema.getpostman.com/json/collection/v2.1.0/collection.json");
    collection["info"] = info;

    QJsonArray items;

    const auto rootNodes = workspace->nodes();

    for (TreeNode* node : rootNodes) {
        items.append(buildItem(node));
    }

    collection["item"] = items;

    QJsonDocument doc(collection);

    return QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
}

QJsonObject PostmanExporter::buildItem(TreeNode* node)
{
    if (!node) {
        return {};
    }

    if (node->nodeType() == RstEnums::NodeType::FolderNode) {
        auto folder = static_cast<Folder*>(node);

        QJsonObject folderJson;
        folderJson["name"] = folder->name();

        QJsonArray children;
        const auto childList = folder->nodes();

        for (TreeNode* child : childList) {
            children.append(buildItem(child));
        }

        folderJson["item"] = children;

        return folderJson;
    }
    else if (node->nodeType() == RstEnums::NodeType::QueryNode) {
        auto query = static_cast<Query*>(node);

        QJsonObject requestJson;
        requestJson["name"] = query->name();
        requestJson["request"] = buildRequest(query);

        return requestJson;
    }

    return {};
}

QJsonObject PostmanExporter::buildRequest(Query* query)
{
    QJsonObject request;
    request["method"] = Util::getQueryTypeString(query->queryType());

    // URL
    QUrl originalUrl(query->url(), QUrl::TolerantMode);
    QString rawUrl = originalUrl.isValid() ? originalUrl.toString(QUrl::RemoveQuery) : query->url();

    QJsonObject urlObj = buildUrl(rawUrl, query->paramList());
    request["url"] = urlObj;

    // Headers
    QJsonArray headersArr = mapToKeyValueArray(query->headerList());
    request["header"] = headersArr;

    // Body
    QJsonObject bodyObj = buildBody(query->bodyType(), query->body());
    request["body"] = bodyObj;

    return request;
}

QJsonObject PostmanExporter::buildUrl(const QString& rawUrl, const QList<QueryParam>& params)
{
    QJsonObject urlObj;
    urlObj["raw"] = rawUrl;

    QJsonArray pathArray;
    QUrl qurl(rawUrl);
    QString host = qurl.host();
    QStringList path = qurl.path().split('/');

    if (host.isEmpty()) { // host is may be variable
        auto parts = rawUrl.split('/');

        if (!parts.isEmpty() && parts[0].startsWith("{{")) {
            host = parts.first();
            path.removeFirst(); // remove host variable
        }
    }

    if (qurl.port() != -1) {
        host += ":" + QString::number(qurl.port());
    }

    for (const auto& str : path) {
        pathArray.append(str);
    }

    urlObj["host"] = host;
    urlObj["path"] = pathArray;
    urlObj["protocol"] = qurl.scheme();

    // Query parameters
    QJsonArray queryArr;

    for (const auto& p : params) {
        QJsonObject param;
        param["key"] = p.name();
        param["value"] = p.value();
        param["diabled"] = !p.isEnabled();

        queryArr.append(param);
    }

    urlObj["query"] = queryArr;

    return urlObj;
}

QJsonObject PostmanExporter::buildBody(RstEnums::BodyType type, const QString& bodyText)
{
    QJsonObject body;

    switch (type) {
    case RstEnums::BodyType::JSON:
        body["mode"] = QStringLiteral("raw");
        body["raw"] = bodyText.isEmpty() ? QStringLiteral("{}") : bodyText;
        {
            QJsonObject options;
            QJsonObject rawOpt;
            rawOpt["language"] = QStringLiteral("json");
            options["raw"] = rawOpt;
            body["options"] = options;
        }
        break;
    case RstEnums::BodyType::XML:
        body["mode"] = QStringLiteral("raw");
        body["raw"] = bodyText;
        {
            QJsonObject options;
            QJsonObject rawOpt;
            rawOpt["language"] = QStringLiteral("xml");
            options["raw"] = rawOpt;
            body["options"] = options;
        }
        break;
    case RstEnums::BodyType::URL_ENCODED_FORM:
        body["mode"] = QStringLiteral("urlencoded");
        body["urlencoded"] = QJsonArray();
        break;
    case RstEnums::BodyType::MULTIPART_FORM:
        body["mode"] = QStringLiteral("formdata");
        body["formdata"] = QJsonArray();
        break;
    case RstEnums::BodyType::NONE:
    default:
        body["mode"] = QStringLiteral("raw");
        body["raw"] = QString();
        break;
    }

    return body;
}

QJsonArray PostmanExporter::mapToKeyValueArray(const QList<QueryParam>& headerList)
{
    QJsonArray arr;

    for (const auto& header : headerList) {
        QJsonObject obj;
        obj["key"] = header.name();
        obj["value"] = header.value();
        obj["type"] = "text";
        obj["disabled"] = !header.isEnabled();

        arr.append(obj);
    }

    return arr;
}
