#include "har_request.h"

HarRequest HarRequest::fromJson(QJsonObject&& json) noexcept
{
    HarRequest request;
    request.url = json.value("url").toString();
    request.method = json.value("method").toString();
    request.postData = HarPostData::fromJson(json.value("postData").toObject());

    QJsonArray headersArray = json.value("headers").toArray();
    QJsonArray queryParams = json.value("queryString").toArray();

    request.headers.reserve(headersArray.size());
    request.queryString.reserve(queryParams.size());

    for (auto&& header : headersArray) {
        request.headers << HarItem::fromJson(header.toObject());
    }

    for (auto&& param : queryParams) {
        request.queryString << HarItem::fromJson(param.toObject());
    }

    return request;
}

Query* HarRequest::toQuery() noexcept
{
    auto urlArr = url.split("?");

    auto qry = new Query();
    qry->setUuid(Util::uuid());
    qry->setUrl(urlArr.first());
    qry->setName(urlArr.first().replace("http://", "").replace("https://", ""));

    QVariantMap queryHeaders;
    QVariantList queryParams;
    queryParams.reserve(queryParams.size());

    for (const HarItem& header : headers) {
        queryHeaders[header.name] = header.value;
    }

    for (const HarItem& param : queryString) {
        QVariantMap map = {
            { "isEnabled", true },
            { "name", param.name },
            { "value", param.value },
        };
        queryParams << map;
    }

    qry->setHeaders(queryHeaders);
    qry->setParams(queryParams);
    qry->setQueryType(Util::getQueryType(method));

    bool isDataRaw = postData.mimeType.contains("multipart/form-data");
    bool isUrlEncoded = postData.mimeType.contains("application/x-www-form-urlencoded");

    if (isDataRaw) {
        auto parsedForm = parseDataRaw(postData.text);

        for (const QString& key : parsedForm.keys()) {
            qry->addFormData(key, parsedForm[key]);
        }

        qry->setBodyType(BodyType::MULTIPART_FORM);
    }

    if (isUrlEncoded) {
        /* code */
        qry->setBodyType(BodyType::URL_ENCODED_FORM);
    }

    if (!isDataRaw && !isUrlEncoded && !postData.text.isEmpty()) {
        qry->setBody(postData.text);

        if (postData.mimeType.contains("application/json")) {
            qry->setBodyType(BodyType::JSON);
        }

        if (postData.mimeType.contains("application/xml")) {
            qry->setBodyType(BodyType::XML);
        }
    }

    return qry;
}

QMap<QString, QString> HarRequest::parseDataRaw(const QString& dataRaw) noexcept
{
    if (dataRaw.isEmpty()) {
        return {};
    }

    QMap<QString, QString> queryParams;
    QRegularExpression nameRegExp("name=\"([^\"]*)\"");
    QStringList items = dataRaw.split(QRegularExpression("\n|\r\n|rn|\r"), Qt::SkipEmptyParts);

    if (items.isEmpty()) {
        return {};
    }

    QString del1 = items[0];
    QString del2 = items[0].replace("$", "");
    QStringList itemsByDelimeter = dataRaw.split(QRegularExpression(del1 + "|" + del2), Qt::SkipEmptyParts);
    QRegularExpression lineRegExp("rnrn|\r\n\r\n");

    for (const QString& item : itemsByDelimeter) {
        // QStringList itemsByLineBreaker = item.split("rnrn", Qt::SkipEmptyParts);
        QStringList itemsByLineBreaker = item.split(lineRegExp, Qt::SkipEmptyParts);

        if (itemsByLineBreaker.size() < 2) {
            continue;
        }

        QString name;
        QRegularExpressionMatch match = nameRegExp.match(item);

        if (match.hasMatch()) {
            name = match.captured(1);
        } else {
            continue;
        }

        QString value = itemsByLineBreaker[1]
                            .replace("rn", "")
                            .replace("\r\n", "");

        // queryParams << QueryParam(name, value);
        // queryParams << { name, value };
        queryParams[name] = value;
    }

    return queryParams;
}
