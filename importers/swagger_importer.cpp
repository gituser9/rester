#include "swagger_importer.h"
#include <QDebug>

std::shared_ptr<Workspace> SwaggerImporter::importWorkspace(const QString& path)
{
    QByteArray fileData = getJson(path);

    if (fileData.isEmpty()) {
        return nullptr;
    }

    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(fileData, &error);

    if (doc.isNull()) {
        return nullptr;
    }

    QJsonObject root = doc.object();

    auto workspace = std::make_shared<Workspace>();
    workspace->createDefault();

    QString title = root.value("info").toObject().value("title").toString("Swagger API");
    workspace->setName(title);
    workspace->setUuid(Util::uuid());

    QString baseUrl = extractBaseUrl(root);
    QMap<QString, Folder*> foldersMap;

    _securitySchemes = extractSecurity(root);
    _globalSecurity = root.value("security").toArray();

    // endpoints
    QJsonObject paths = root.value("paths").toObject();
    for (auto pathIt = paths.begin(); pathIt != paths.end(); ++pathIt) {
        QString path = pathIt.key();
        QJsonObject methods = pathIt.value().toObject();

        for (auto methodIt = methods.begin(); methodIt != methods.end(); ++methodIt) {
            QString methodStr = methodIt.key().toUpper();
            QJsonObject operation = methodIt.value().toObject();

            QString tagName = "";
            QJsonArray tags = operation.value("tags").toArray();

            if (!tags.isEmpty()) {
                tagName = tags.first().toString();
            }

            auto query = new Query();
            query->setUuid(Util::uuid());
            query->setNodeType(RstEnums::NodeType::QueryNode);

            if (tagName.isEmpty()) {
                query->setParent(workspace.get());
                workspace->addNode(query);
            }
            else {
                if (!foldersMap.contains(tagName)) {
                    auto folder = new Folder(workspace.get());
                    folder->setName(tagName);
                    folder->setUuid(Util::uuid());
                    folder->setNodeType(RstEnums::NodeType::FolderNode);

                    foldersMap.insert(tagName, folder);
                    workspace->addNode(folder);
                }

                auto fldr = foldersMap[tagName];
                query->setParent(fldr);
                fldr->addNode(query);
            }

            query->setName(operation.value("operationId").toString(path));
            query->setUrl(baseUrl + path);
            query->setQueryType(Util::getQueryType(methodStr));

            // security
            setSecurity(root, operation, query);

            // query params and headers
            setParams(operation, query);

            query->setBodyType(detectBodyType(operation));

            if (query->bodyType() == RstEnums::BodyType::JSON) {
                query->setBody("{}");
            }
        }
    }

    return workspace;
}

QString SwaggerImporter::extractBaseUrl(const QJsonObject& root)
{
    QString baseUrl = "";

    // OpenAPI 3.0
    if (root.contains("servers")) {
        QJsonArray servers = root.value("servers").toArray();

        if (!servers.isEmpty()) {
            baseUrl = servers.first().toObject().value("url").toString();
        }
    }
    // Swagger 2.0
    else if (root.contains("host")) {
        QString scheme = "http";

        if (root.contains("schemes")) {
            QJsonArray schemes = root.value("schemes").toArray();

            if (!schemes.isEmpty()) {
                scheme = schemes.first().toString();
            }
        }

        baseUrl = scheme + "://" + root.value("host").toString() + root.value("basePath").toString("");
    }

    if (baseUrl.endsWith('/')) {
        baseUrl.chop(1);
    }

    return baseUrl;
}

RstEnums::BodyType SwaggerImporter::detectBodyType(const QJsonObject& operation)
{
    // OpenAPI 3.0
    if (operation.contains("requestBody")) {
        QJsonObject content = operation.value("requestBody").toObject().value("content").toObject();

        if (content.contains("application/json")) {
            return RstEnums::BodyType::JSON;
        }
        else if (content.contains("multipart/form-data")) {
            return RstEnums::BodyType::MULTIPART_FORM;
        }
        else if (content.contains("application/x-www-form-urlencoded")) {
            return RstEnums::BodyType::URL_ENCODED_FORM;
        }
        else if (content.contains("application/xml")) {
            return RstEnums::BodyType::XML;
        }
    }

    // Swagger 2.0
    if (operation.contains("consumes")) {
        QJsonArray consumes = operation.value("consumes").toArray();

        for (const QJsonValueRef& val : consumes) {
            QString type = val.toString();

            if (type.contains("json")) {
                return RstEnums::BodyType::JSON;
            }

            if (type.contains("multipart/form-data")) {
                return RstEnums::BodyType::MULTIPART_FORM;
            }

            if (type.contains("x-www-form-urlencoded")) {
                return RstEnums::BodyType::URL_ENCODED_FORM;
            }

            if (type.contains("xml")) {
                return RstEnums::BodyType::XML;
            }
        }
    }

    return RstEnums::BodyType::NONE;
}

QMap<QString, SecurityScheme> SwaggerImporter::extractSecurity(const QJsonObject& root)
{
    QMap<QString, SecurityScheme> securitySchemes;

    // OpenAPI 3.x
    QJsonObject components = root.value("components").toObject();
    QJsonObject schemesObj = components.value("securitySchemes").toObject();

    // Swagger 2.0 (fallback)
    if (schemesObj.isEmpty()) {
        schemesObj = root.value("securityDefinitions").toObject();
    }

    for (auto it = schemesObj.begin(); it != schemesObj.end(); ++it) {
        QJsonObject s = it.value().toObject();
        SecurityScheme scheme;
        scheme.type = s.value("type").toString();
        scheme.name = s.value("name").toString();
        scheme.in = s.value("in").toString();
        scheme.scheme = s.value("scheme").toString().toLower();
        securitySchemes.insert(it.key(), scheme);
    }

    return securitySchemes;
}

QByteArray SwaggerImporter::getJson(const QString& path)
{
    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        return "";
    }

    QByteArray jsonData = file.readAll();
    file.close();

    return jsonData;
}

void SwaggerImporter::setSecurity(const QJsonObject& root, const QJsonObject& operation, Query* query)
{
    QJsonArray activeSecurity = operation.contains("security")
                                    ? operation.value("security").toArray()
                                    : _globalSecurity;

    for (const QJsonValueRef& secReqValue : activeSecurity) {
        QJsonObject secReq = secReqValue.toObject();

        for (auto secIt = secReq.begin(); secIt != secReq.end(); ++secIt) {
            QString schemeName = secIt.key();

            if (_securitySchemes.contains(schemeName)) {
                const auto& s = _securitySchemes[schemeName];

                // API Key header
                if (s.type == "apiKey" && s.in == "header") {
                    query->addHeader(s.name, "");
                }
                // HTTP Bearer or Basic
                else if (s.type == "http") {
                    if (s.scheme == "bearer") {
                        query->addHeader("Authorization", "Bearer ");
                    }
                    else if (s.scheme == "basic") {
                        query->addHeader("Authorization", "Basic ");
                    }
                }
                // OAuth2
                else if (s.type == "oauth2") {
                    query->addHeader("Authorization", "Bearer ");
                }
            }
        }
    }
}

void SwaggerImporter::setParams(const QJsonObject& operation, Query* query)
{
    QJsonArray parameters = operation.value("parameters").toArray();

    for (const QJsonValueRef& paramVal : parameters) {
        QJsonObject paramObj = paramVal.toObject();
        QString in = paramObj.value("in").toString();
        QString name = paramObj.value("name").toString();

        if (in == "query") {
            query->addParam(name, "");
        }
        else if (in == "header") {
            query->addHeader(name, "");
        }
    }
}
