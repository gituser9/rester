#include "query.h"

Query::Query(TreeNode* parent) : TreeNode(parent)
{
    _queryType = RstEnums::QueryType::GET;
    _bodyType = RstEnums::BodyType::NONE;
    _lastAnswer = QSharedPointer<HttpAnswer>();

    setNodeType(RstEnums::NodeType::QueryNode);
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

QVariantList Query::headers() const
{
    QVariantList list;
    list.reserve(_headers.count());

    for (const QueryParam& item : _headers) {
        list << QVariant::fromValue(item);
    }

    return list;
}

void Query::setHeaders(const QVariantList& newHeaders)
{
    _headers.clear();

    for (const QVariant& item : newHeaders) {
        QVariantMap map = item.toMap();

        _headers << QueryParam(map);
    }

    emit headersChanged();
    emit dataChanged();
}

void Query::setHeaders(const QList<QueryParam>& newHeaders)
{
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

RstEnums::BodyType Query::bodyType() const
{
    return _bodyType;
}

void Query::setBodyType(RstEnums::BodyType newBodyType)
{
    if (_bodyType == newBodyType) {
        return;
    }

    _bodyType = newBodyType;

    emit bodyTypeChanged();
    emit dataChanged();
}

RstEnums::QueryType Query::queryType() const
{
    return _queryType;
}

void Query::setQueryType(RstEnums::QueryType newQueryType)
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
    _body = json.value("body").toString("");

    setUuid(json.value("uuid").toString(Util::uuid()));
    setName(json.value("name").toString(""));
    setNodeType(RstEnums::NodeType::QueryNode);

    if (json.contains("last_answer")) {
        QJsonObject answerJson = json.value("last_answer").toObject();

        auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
        answer->fromJson(std::move(answerJson));

        _lastAnswer = answer;

        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);
    }
    else {
        _lastAnswer = QSharedPointer<HttpAnswer>();
    }

    auto paramsArr = json.value("params").toArray();

    for (QJsonValueRef item : paramsArr) {
        QueryParam param(item.toObject());
        _paramList << param;
    }

    auto formArr = json.value("form_data").toArray();

    for (QJsonValueRef item : formArr) {
        QueryParam param(item.toObject());
        _formDataList << param;
    }

    auto headersArr = json.value("headers").toArray();

    for (QJsonValueRef item : headersArr) {
        QueryParam param(item.toObject());
        _headers << param;
    }
}

QJsonObject Query::toJson() const
{
    QJsonObject json;
    json["url"] = _url;
    json["query_type"] = Util::getQueryTypeString(_queryType);
    json["body_type"] = Util::getBodyTypeString(_bodyType);
    json["node_type"] = static_cast<int>(RstEnums::NodeType::QueryNode);
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

    QJsonArray headerArray;

    for (const QueryParam& param : _headers) {
        headerArray << param.toJson();
    }

    json["headers"] = headerArray;

    return json;
}

void Query::setAnswer(QSharedPointer<HttpAnswer> ptr)
{
    if (!_lastAnswer.isNull()) {
        disconnect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);
    }

    _lastAnswer.reset();
    _lastAnswer = ptr;

    if (!_lastAnswer.isNull()) {
        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &Query::dataChanged);
    }

    emit lastAnswerChanged();
    emit dataChanged();
}

void Query::beautify() noexcept
{
    setBody(Util::beautify(_body, _bodyType));
}

void Query::addHeader(const QString& name, const QString& value)
{
    QueryParam param(name, value);

    _headers << param;

    emit headersChanged();
    emit dataChanged();
}

void Query::addHeader(const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param(name, value, isEnabled);

    _headers << param;

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

void Query::addParam(const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param(name, value, isEnabled);

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

void Query::addFormData(const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param(name, value, isEnabled);

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

void Query::removeHeader(int index)
{
    _headers.removeAt(index);

    emit headersChanged();
    emit dataChanged();
}

void Query::removeHeader(const QString& name)
{
    QList<QueryParam> newHeaders;
    newHeaders.reserve(_headers.size());

    for (QueryParam& header : _headers) {
        if (header.name() == name) {
            continue;
        }

        newHeaders << header;
    }

    _headers = newHeaders;

    emit headersChanged();
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

void Query::setHeader(int index, const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param = _headers[index];
    param.setName(name);
    param.setValue(value);
    param.setIsEnabled(isEnabled);

    _headers[index] = param;

    emit headersChanged();
    emit dataChanged();
}

void Query::setHeader(const QString& name, const QString& value)
{
    bool isExists = false;

    for (QueryParam& header : _headers) {
        if (header.name() == name) {
            header.setValue(value);

            isExists = true;

            break;
        }
    }

    if (!isExists) {
        QueryParam param(name, value);
        _headers << param;
    }

    emit headersChanged();
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
    }
    else if (contentType.contains("xml")) {
        fileExt = "xml";
    }
    else if (contentType.contains("html")) {
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

QList<QueryParam> Query::formDataList() const noexcept
{
    return _formDataList;
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

QList<QueryParam> Query::headerList() const noexcept
{
    return _headers;
}
