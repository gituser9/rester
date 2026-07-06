#include "postman_importer.h"

std::shared_ptr<Workspace> PostmanImporter::importWorkspace(const QString& path)
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
    QJsonObject info = root.value("info").toObject();

    auto workspace = std::make_shared<Workspace>();
    workspace->createDefault();
    workspace->setName(info.value("name").toString("Postman Collection"));
    workspace->setUuid(Util::uuid());

    QJsonObject rootAuth = root.value("auth").toObject();
    QJsonArray items = root.value("item").toArray();

    for (const QJsonValueRef& itemVal : items) {
        parseItem(itemVal.toObject(), workspace.get(), rootAuth);
    }

    return workspace;
}

void PostmanImporter::parseItem(const QJsonObject& itemObj, TreeNode* parent, const QJsonObject& parentAuth)
{
    // check auth
    QJsonObject currentAuth = parentAuth;

    if (itemObj.contains("auth")) {
        QJsonObject itemAuth = itemObj.value("auth").toObject();
        QString type = itemAuth.value("type").toString();

        if (type == "noauth") {
            currentAuth = QJsonObject();
        }
        else if (type != "inherit") {
            currentAuth = itemAuth;
        }
    }

    // is folder
    if (itemObj.contains("item")) {
        auto* folder = new Folder(parent);
        folder->setName(itemObj.value("name").toString("Folder"));
        folder->setUuid(Util::uuid());
        folder->setNodeType(RstEnums::NodeType::FolderNode);

        parent->addNode(folder);

        // is nested folder
        QJsonArray children = itemObj.value("item").toArray();

        for (const QJsonValueRef& childVal : children) {
            parseItem(childVal.toObject(), folder, currentAuth);
        }
    }
    // is query
    else if (itemObj.contains("request")) {
        auto* query = new Query(parent);
        query->setName(itemObj.value("name").toString("Request"));
        query->setUuid(Util::uuid());

        parent->addNode(query);

        QJsonObject reqObj = itemObj.value("request").toObject();

        // HTTP
        query->setQueryType(Util::getQueryType(reqObj.value("method").toString("GET")));

        // URL / params
        QJsonValue urlVal = reqObj.value("url");
        QString rawUrl;

        if (urlVal.isString()) {
            rawUrl = urlVal.toString();
        }
        else if (urlVal.isObject()) {
            rawUrl = urlVal.toObject().value("raw").toString();
        }

        query->setUrl(rawUrl);
        query->parseParams();

        // headers
        QJsonArray headers = reqObj.value("header").toArray();

        for (const QJsonValueRef& headerVal : headers) {
            QJsonObject hObj = headerVal.toObject();

            query->addHeader(hObj.value("key").toString(), hObj.value("value").toString());
        }

        // body
        setBody(reqObj, query);

        // auth
        if (!currentAuth.isEmpty()) {
            setAuth(currentAuth, query);
        }
    }
}

void PostmanImporter::setAuth(const QJsonObject& authObj, Query* query)
{
    QString type = authObj.value("type").toString();

    if (type.isEmpty()) {
        return;
    }

    QJsonArray authProps = authObj.value(type).toArray();
    QMap<QString, QString> propsMap;

    for (const QJsonValueRef& val : authProps) {
        QJsonObject prop = val.toObject();
        propsMap.insert(prop.value("key").toString(), prop.value("value").toString());
    }

    if (type == "bearer") {
        QString token = propsMap.value("token");
        query->addHeader("Authorization", "Bearer " + token);
    }
    else if (type == "basic") {
        QString user = propsMap.value("username");
        QString pass = propsMap.value("password");
        QString credentials = user + ":" + pass;
        QString b64 = QString::fromUtf8(credentials.toUtf8().toBase64()); // Basic Auth required base64(user:pass)

        query->addHeader("Authorization", "Basic " + b64);
    }
    else if (type == "apikey") {
        QString key = propsMap.value("key", "api_key");
        QString val = propsMap.value("value");
        QString in = propsMap.value("in", "header");

        if (in == "header") {
            query->addHeader(key, val);
        }
        else if (in == "query") {
            query->addParam(key, val);
        }
    }
}

QByteArray PostmanImporter::getJson(const QString& path)
{
    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        return "";
    }

    QByteArray jsonData = file.readAll();
    file.close();

    return jsonData;
}

void PostmanImporter::setBody(const QJsonObject& reqObj, Query* query)
{
    QJsonObject bodyObj = reqObj.value("body").toObject();
    QString mode = bodyObj.value("mode").toString();

    if (mode == "raw") {
        query->setBody(bodyObj.value("raw").toString());

        QString lang = bodyObj
                           .value("options")
                           .toObject()
                           .value("raw")
                           .toObject()
                           .value("language")
                           .toString();

        if (lang == "json") {
            query->setBodyType(RstEnums::BodyType::JSON);
        }
        else if (lang == "xml") {
            query->setBodyType(RstEnums::BodyType::XML);
        }
        else {
            query->setBodyType(RstEnums::BodyType::NONE);
        }
    }
    else if (mode == "formdata") {
        query->setBodyType(RstEnums::BodyType::MULTIPART_FORM);

        QJsonArray formdata = bodyObj.value("formdata").toArray();

        for (const QJsonValueRef& fdVal : formdata) {
            QJsonObject fdObj = fdVal.toObject();

            query->addFormData(
                fdObj.value("key").toString(),
                fdObj.value("value").toString() //
            );
        }
    }
    else if (mode == "urlencoded") {
        query->setBodyType(RstEnums::BodyType::URL_ENCODED_FORM);

        QJsonArray urlencoded = bodyObj.value("urlencoded").toArray();

        for (const QJsonValueRef& fdVal : urlencoded) {
            QJsonObject fdObj = fdVal.toObject();

            query->addFormData(
                fdObj.value("key").toString(),
                fdObj.value("value").toString() //
            );
        }
    }
    else {
        query->setBodyType(RstEnums::BodyType::NONE);
    }
}
