#include "query.h"

Query::Query(TreeNode* parent)
    : TreeNode(parent)
{
    _queryType = QueryType::GET;
    _bodyType = BodyType::NONE;
    _lastAnswer = QSharedPointer<HttpAnswer>();

    setNodeType(NodeType::QueryNode);
}

Query::~Query()
{
    _lastAnswer.clear();
}

HttpAnswer* Query::lastAnswer() const
{
    if (_lastAnswer.isNull()) {
        return nullptr;
    }

    return _lastAnswer.get();
}

void Query::setLastAnswer(HttpAnswer* newLastAnswer)
{
    disconnect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);

    _lastAnswer.reset();
    _lastAnswer = QSharedPointer<HttpAnswer>(newLastAnswer);
    _lastAnswer->beautify();

    if (newLastAnswer != nullptr) {
        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);
    }

    emit lastAnswerChanged();
    emit dataChanged();
}

QString Query::body() const
{
    return _body;
}

void Query::setBody(const QString& newBody)
{
    if (_body == newBody) {
        return;
    }

    QString cleanBody = newBody;
    _body = cleanBody.replace("&quot;", "\"");

    emit bodyChanged();
    emit dataChanged();
}

QVariantMap Query::headers() const
{
    return _headers;
}

void Query::setHeaders(const QVariantMap& newHeaders)
{
    if (_headers == newHeaders) {
        return;
    }

    _headers = newHeaders;

    emit headersChanged();
    emit dataChanged();
}

QVariantList Query::params() const
{
    QVariantList list;
    list.reserve(_paramList.count());

    for (const QueryParam& item : _paramList) {
        list << QVariant::fromValue(item);
    }

    return list;
}

void Query::setParams(const QVariantList& newParams)
{
    _paramList.clear();

    for (const QVariant& item : newParams) {
        QVariantMap map = item.toMap();

        _paramList << QueryParam(map);
    }

    emit paramsChanged();
    emit dataChanged();
}

BodyType Query::bodyType() const
{
    return _bodyType;
}

void Query::setBodyType(BodyType newBodyType)
{
    if (_bodyType == newBodyType) {
        return;
    }

    _bodyType = newBodyType;

    emit bodyTypeChanged();
    emit dataChanged();
}

QueryType Query::queryType() const
{
    return _queryType;
}

void Query::setQueryType(QueryType newQueryType)
{
    if (_queryType == newQueryType) {
        return;
    }

    _queryType = newQueryType;

    emit queryTypeChanged();
    emit dataChanged();
}

QString Query::url() const
{
    return _url;
}

void Query::setUrl(const QString& newUrl)
{
    if (_url == newUrl) {
        return;
    }

    _url = newUrl;

    emit urlChanged();
    emit dataChanged();
}

void Query::fromJson(QJsonObject json)
{
    _url = json.value("url").toString("");
    _queryType = Util::getQueryType(json.value("query_type").toString("GET"));
    _bodyType = Util::getBodyType(json.value("body_type").toString("None"));
    _headers = json.value("headers").toObject().toVariantMap();
    _body = json.value("body").toString("");

    setUuid(json.value("uuid").toString(Util::uuid()));
    setName(json.value("name").toString(""));
    setNodeType(NodeType::QueryNode);

    if (json.contains("last_answer")) {
        QJsonObject answerJson = json.value("last_answer").toObject();

        auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
        answer->fromJson(std::move(answerJson));

        _lastAnswer = answer;

        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);
    } else {
        _lastAnswer = QSharedPointer<HttpAnswer>();
    }

    if (json.value("params").isObject()) {
        auto paramsObj = json.value("params").toObject().toVariantMap();

        QMapIterator iter(paramsObj);

        while (iter.hasNext()) {
            iter.next();

            QueryParam param(iter.key(), iter.value().toString());
            _paramList << param;
        }
    } else if (json.value("params").isArray()) {
        auto paramsArr = json.value("params").toArray();

        for (QJsonValueRef item : paramsArr) {
            QueryParam param(item.toObject());
            _paramList << param;
        }
    }

    if (json.value("form_data").isObject()) {
        auto paramsObj = json.value("form_data").toObject().toVariantMap();

        QMapIterator iter(paramsObj);

        while (iter.hasNext()) {
            iter.next();

            QueryParam param(iter.key(), iter.value().toString());
            _formDataList << param;
        }
    } else if (json.value("form_data").isArray()) {
        auto paramsArr = json.value("form_data").toArray();

        for (QJsonValueRef item : paramsArr) {
            QueryParam param(item.toObject());
            _formDataList << param;
        }
    }
}

QJsonObject Query::toJson() const
{
    QJsonObject json;
    json["url"] = _url;
    json["query_type"] = Util::getQueryTypeString(_queryType);
    json["body_type"] = Util::getBodyTypeString(_bodyType);
    json["node_type"] = NodeType::QueryNode;
    json["headers"] = QJsonObject::fromVariantMap(_headers);
    json["body"] = _body;
    json["uuid"] = uuid();
    json["name"] = name();

    if (!_lastAnswer.isNull()) {
        json["last_answer"] = _lastAnswer->toJson();
    }

    QJsonArray paramArray;

    for (const QueryParam& param : _paramList) {
        paramArray << param.toJson();
    }

    json["params"] = paramArray;

    QJsonArray formArray;

    for (const QueryParam& param : _formDataList) {
        formArray << param.toJson();
    }

    json["form_data"] = formArray;

    return json;
}

void Query::setAnswer(QSharedPointer<HttpAnswer> ptr)
{
    // disconnect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);

    _lastAnswer.reset();
    _lastAnswer = ptr;

    if (!_lastAnswer.isNull()) {
        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);
    }

    emit lastAnswerChanged();
    emit dataChanged();
}

QVariant Query::getHeader(const QString& name) const
{
    if (_headers.contains(name)) {
        return _headers[name];
    }

    return "";
}

void Query::beautify() noexcept
{
    setBody(Util::beautify(_body, _bodyType));
}

void Query::addHeader(const QString& name, const QString& value)
{
    _headers[name] = value;

    emit headersChanged();
    emit dataChanged();
}

void Query::addParam(const QString& name, const QString& value)
{
    QueryParam param(name, value);

    _paramList << param;

    emit paramsChanged();
    emit dataChanged();
}

void Query::addFormData(const QString& name, const QString& value)
{
    QueryParam param(name, value);
    _formDataList << param;

    emit formDataChanged();
    emit dataChanged();
}

void Query::removeParam(int index)
{
    _paramList.removeAt(index);

    emit paramsChanged();
    emit dataChanged();
}

void Query::removeFormDateItem(int index)
{
    _formDataList.removeAt(index);

    emit formDataChanged();
    emit dataChanged();
}

void Query::setParam(int index, const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param = _paramList[index];
    param.setName(name);
    param.setValue(value);
    param.setIsEnabled(isEnabled);

    _paramList[index] = param;

    emit paramsChanged();
    emit dataChanged();
}

void Query::setFormDataItem(int index, const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param = _formDataList[index];
    param.setName(name);
    param.setValue(value);
    param.setIsEnabled(isEnabled);

    _formDataList[index] = param;

    emit formDataChanged();
    emit dataChanged();
}

QSharedPointer<InsomniaBody> Query::buildInsomniaBody() const noexcept
{
    auto body = QSharedPointer<InsomniaBody>(new InsomniaBody);

    switch (_queryType) {
    case QueryType::GET:
    case QueryType::HEAD:
        return body;
    default:
        break;
    }

    if (_bodyType == BodyType::MULTIPART_FORM) {
        QList<InsomniaParam> params(_formDataList.size());

        body->mimeType = "multipart/form-data";

        for (const QueryParam& item : _formDataList) {
            InsomniaParam param;
            param.name = item.name();
            param.value = item.value();

            params.append(param);
        }
        body->params = params;

        return body;
    }

    if (_bodyType == BodyType::JSON) {
        body->mimeType = "application/json";
        body->text = _body;

        return body;
    }

    if (_bodyType == BodyType::XML) {
        body->mimeType = "application/xml";
        body->text = _body;

        return body;
    }

    if (_bodyType == BodyType::URL_ENCODED_FORM) {
        QList<InsomniaParam> params(_formDataList.size());

        body->mimeType = "application/x-www-form-urlencoded";

        for (const QueryParam& item : _formDataList) {
            InsomniaParam param;
            param.name = item.name();
            param.value = item.value();

            params << param;
        }

        body->params = params;

        return body;
    }

    return body;
}

void Query::parseParams() noexcept
{
    QStringList strs = _url.split("?");

    if (strs.size() == 1) {
        return;
    }

    QString paramString = strs.last();
    QStringList paramPairs = paramString.split("&");

    if (!paramPairs.isEmpty()) {
        _paramList.clear();
    }

    for (const QString& pair : paramPairs) {
        QStringList keyValPair = pair.split("=");
        QueryParam param(keyValPair.first(), keyValPair.last());

        _paramList << param;
    }

    _url = strs.first();

    emit urlChanged();
    emit paramsChanged();
    emit dataChanged();
}

QString Query::fileNameForAnswer() const noexcept
{
    QString fileExt = "txt";
    QVariantMap headers = _lastAnswer->headers();
    QString contentType = Util::getHeaderValue("Content-Type", _lastAnswer->headers());

    if (contentType.contains("json")) {
        fileExt = "json";
    } else if (contentType.contains("xml")) {
        fileExt = "xml";
    } else if (contentType.contains("html")) {
        fileExt = "html";
    }

    qint64 ts = QDateTime::currentSecsSinceEpoch();
    QString name = this->name().replace("/", "_").replace("\\", "_");

    return QString("%1_%2.%3").arg(name, QString::number(ts), fileExt);
}

QVariantList Query::formData() const
{
    QVariantList list;
    list.reserve(_formDataList.count());

    for (const QueryParam& item : _formDataList) {
        list << QVariant::fromValue(item);
    }

    return list;
}

void Query::setFormData(const QVariantList& newFormData)
{
    _formDataList.clear();

    for (const QVariant& item : newFormData) {
        _formDataList << QueryParam(item);
    }

    emit formDataChanged();
    emit dataChanged();
}

QList<QueryParam> Query::paramList() const noexcept
{
    return _paramList;
}

InsomniaResource Query::toInsomniaResource(const QString& parentId) const noexcept
{
    // to ctor
    auto millis = QDateTime::currentMSecsSinceEpoch();
    QList<InsomniaHeader> headers(_headers.size());
    QList<InsomniaHeader> params(_paramList.size());

    for (const QueryParam& param : _paramList) {
        InsomniaHeader head;
        head.name = param.name();
        head.value = param.value();
        head.disabled = !param.isEnabled();

        params << head;
    }

    QMapIterator iter(_headers);

    while (iter.hasNext()) {
        iter.next();

        InsomniaHeader head;
        head.name = iter.key();
        head.value = iter.value().toString();

        headers << head;
    }

    InsomniaResource resource;
    resource.id = InsomniaQueryPrefix + Util::uuid();
    resource.parentId = parentId;
    resource.modified = millis;
    resource.created = millis;
    resource.url = _url;
    resource.name = name();
    resource.method = Util::getQueryTypeString(_queryType);
    resource.body = buildInsomniaBody();
    resource.parameters = params;
    resource.headers = headers;

    return resource;
}

PostmanItem Query::toPostmanItem() const noexcept
{
    PostmanItem postmanItem;
    postmanItem.name = name();
    postmanItem.request.method = Util::getQueryTypeString(queryType());

    QMapIterator iter(_headers);

    while (iter.hasNext()) {
        iter.next();

        PostmanHeader header;
        header.key = iter.key();
        header.value = iter.value().toString();

        postmanItem.request.headers << header;
    }

    QUrl qurl(_url);
    QString host = qurl.host();

    if (qurl.port() != -1) {
        host += ":" + QString::number(qurl.port());
    }

    PostmanUrl postmanUrl;
    postmanUrl.raw = _url;
    postmanUrl.protocol = qurl.scheme();
    postmanUrl.host = QStringList { host };
    postmanUrl.path = qurl.path().split('/');

    for (const QueryParam& param : _paramList) {
        QVariantMap paramMap;
        paramMap["key"] = param.name();
        paramMap["value"] = param.value();

        postmanUrl.query << paramMap;
    }

    postmanItem.request.url = postmanUrl;

    // Set body
    if (_bodyType == BodyType::JSON) {
        PostmanRequestBody body;
        body.mode = "raw";
        body.raw = _body;
        body.options.language = "json";

        postmanItem.request.body = body;
    }

    if (_bodyType == BodyType::MULTIPART_FORM) {
        PostmanRequestBody body;
        body.mode = "formdata";

        for (const QueryParam& data : _formDataList) {
            PostmanFormDataBody item;
            item.key = data.name();
            item.value = data.value();

            body.formdata << item;
        }
        postmanItem.request.body = body;
    }

    return postmanItem;
}
