#include "har_importer.h"

std::shared_ptr<Workspace> HarImporter::import(const QString& path)
{
    QByteArray fileData = getJson(path);

    if (fileData.isEmpty()) {
        return nullptr;
    }

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(fileData, &error);

    if (doc.isNull() || !doc.isObject()) {
        return nullptr;
    }

    QJsonObject root = doc.object();
    QJsonObject logObj = root.value("log").toObject();
    QJsonArray entries = logObj.value("entries").toArray();

    auto workspace = std::make_shared<Workspace>();
    workspace->createDefault();
    workspace->setName("HAR Import");
    workspace->setUuid(Util::uuid());

    for (const QJsonValueRef& entryVal : entries) {
        QJsonObject entry = entryVal.toObject();
        QJsonObject request = entry.value("request").toObject();

        auto query = new Query();
        query->setUuid(Util::uuid());
        query->setNodeType(NodeType::QueryNode);
        query->setParent(workspace.get());
        workspace->addNode(query);

        // Name
        QString url = request.value("url").toString();
        QUrl reqUrl(url);

        query->setName(reqUrl.path());
        query->setUrl(url);

        // Method
        QString method = request.value("method").toString().toUpper();
        query->setQueryType(Util::getQueryType(method));

        // Headers
        QJsonArray headersArr = request.value("headers").toArray();

        for (const QJsonValueRef& hVal : headersArr) {
            QJsonObject hObj = hVal.toObject();
            QString name = hObj.value("name").toString();
            QString value = hObj.value("value").toString();

            if (!name.isEmpty()) {
                query->addHeader(name, value);
            }
        }

        // Query string -> add as parameters
        QJsonArray qsArr = request.value("queryString").toArray();

        for (const QJsonValueRef& qVal : qsArr) {
            QJsonObject qObj = qVal.toObject();
            QString name = qObj.value("name").toString();
            QString value = qObj.value("value").toString();

            if (!name.isEmpty()) {
                query->addParam(name, value);
            }
        }

        // POST data
        QJsonObject postData = request.value("postData").toObject();

        if (!postData.isEmpty()) {
            QString mimeType = postData.value("mimeType").toString();
            BodyType bodyType = detectBodyType(mimeType);
            query->setBodyType(bodyType);

            if (bodyType == BodyType::JSON || bodyType == BodyType::XML) {
                QString text = postData.value("text").toString();
                query->setBody(text);
            }
            else if (bodyType == BodyType::MULTIPART_FORM) {
                QJsonArray paramsArr = postData.value("params").toArray();

                for (const QJsonValue& pVal : paramsArr) {
                    QJsonObject pObj = pVal.toObject();
                    QString key = pObj.value("name").toString();
                    QString val = pObj.value("value").toString();

                    query->addFormData(key, val);
                }
            }
            else if (bodyType == BodyType::URL_ENCODED_FORM) {
                QJsonArray paramsArr = postData.value("params").toArray();

                if (!paramsArr.isEmpty()) {
                    QUrlQuery urlQuery;

                    for (const QJsonValue& pVal : paramsArr) {
                        QJsonObject pObj = pVal.toObject();
                        QString key = pObj.value("name").toString();
                        QString val = pObj.value("value").toString();
                        urlQuery.addQueryItem(key, val);
                    }

                    query->setBody(urlQuery.toString());
                }
                else {
                    QString text = postData.value("text").toString();
                    if (!text.isEmpty()) {
                        query->setBody(text);
                    }
                }
            }
            else {
                QString text = postData.value("text").toString();

                if (!text.isEmpty()) {
                    query->setBody(text);
                }
            }
        }
    }

    return workspace;
}

BodyType HarImporter::detectBodyType(const QString& mimeType)
{
    if (mimeType.contains("json", Qt::CaseInsensitive)) {
        return BodyType::JSON;
    }

    if (mimeType.contains("xml", Qt::CaseInsensitive)) {
        return BodyType::XML;
    }

    if (mimeType.contains("x-www-form-urlencoded", Qt::CaseInsensitive)) {
        return BodyType::URL_ENCODED_FORM;
    }

    if (mimeType.contains("multipart/form-data", Qt::CaseInsensitive)) {
        return BodyType::MULTIPART_FORM;
    }

    return BodyType::NONE;
}

QByteArray HarImporter::getJson(const QString& path)
{
    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        return {};
    }

    QByteArray data = file.readAll();
    file.close();

    return data;
}
