#include "graphql_query.h"

GraphqlQuery::GraphqlQuery(TreeNode* parent) : TreeNode(parent)
{
    _queryType = RstEnums::QueryType::GRAPHQL;
    _lastAnswer = QSharedPointer<HttpAnswer>();

    setNodeType(RstEnums::NodeType::GraphqlQueryNode);
}

GraphqlQuery::~GraphqlQuery()
{
}

RstEnums::QueryType GraphqlQuery::queryType() const
{
    return _queryType;
}

QString GraphqlQuery::url() const
{
    return _url;
}

void GraphqlQuery::setUrl(const QString& newUrl)
{
    if (_url == newUrl) {
        return;
    }

    _url = newUrl;

    emit urlChanged();
    emit dataChanged();
}

QString GraphqlQuery::body() const
{
    return _body;
}

void GraphqlQuery::setBody(const QString& newBody)
{
    if (_body == newBody) {
        return;
    }

    _body = newBody;

    emit bodyChanged();
    emit dataChanged();
}

QVariantList GraphqlQuery::headers() const
{
    QVariantList list;
    list.reserve(_headers.count());

    for (const QueryParam& item : _headers) {
        list << QVariant::fromValue(item);
    }

    return list;
}

void GraphqlQuery::setHeaders(const QVariantList& newHeaders)
{
    _headers.clear();

    for (const QVariant& item : newHeaders) {
        QVariantMap map = item.toMap();

        _headers << QueryParam(map);
    }

    emit headersChanged();
    emit dataChanged();
}

void GraphqlQuery::setHeaders(const QList<QueryParam>& newHeaders)
{
    _headers = newHeaders;

    emit headersChanged();
    emit dataChanged();
}

QVariantList GraphqlQuery::variables() const
{
    QVariantList list;
    list.reserve(_variables.count());

    for (const QueryParam& item : _variables) {
        list << QVariant::fromValue(item);
    }

    return list;
}

void GraphqlQuery::setVariables(const QVariantList& newVariables)
{
    _variables.clear();

    for (const QVariant& item : newVariables) {
        QVariantMap map = item.toMap();

        _variables << QueryParam(map);
    }

    emit variablesChanged();
    emit dataChanged();
}

HttpAnswer* GraphqlQuery::lastAnswer() const
{
    if (_lastAnswer.isNull()) {
        return nullptr;
    }

    return _lastAnswer.get();
}

void GraphqlQuery::setLastAnswer(HttpAnswer* newLastAnswer)
{
    if (!_lastAnswer.isNull()) {
        _lastAnswer->disconnect();
    }

    _lastAnswer.reset();
    _lastAnswer = QSharedPointer<HttpAnswer>(newLastAnswer);
    _lastAnswer->beautify();

    if (newLastAnswer != nullptr) {
        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &GraphqlQuery::dataChanged);
    }

    emit lastAnswerChanged();
    emit dataChanged();
}

void GraphqlQuery::setLastAnswer(QSharedPointer<HttpAnswer> ptr)
{
    _lastAnswer = ptr;

    emit lastAnswerChanged();
    emit dataChanged();
}

QList<QueryParam> GraphqlQuery::headerList() const noexcept
{
    return _headers;
}

QList<QueryParam> GraphqlQuery::variablesList() const noexcept
{
    return _variables;
}

void GraphqlQuery::addHeader(const QString& name, const QString& value)
{
    QueryParam param(name, value);

    _headers << param;

    emit headersChanged();
    emit dataChanged();
}

void GraphqlQuery::addHeader(const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param(name, value, isEnabled);

    _headers << param;

    emit headersChanged();
    emit dataChanged();
}

void GraphqlQuery::setHeader(int index, const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param = _headers[index];
    param.setName(name);
    param.setValue(value);
    param.setIsEnabled(isEnabled);

    _headers[index] = param;

    emit headersChanged();
}

void GraphqlQuery::removeHeader(int index)
{
    _headers.removeAt(index);

    emit headersChanged();
    emit dataChanged();
}

void GraphqlQuery::removeHeader(const QString& name)
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

void GraphqlQuery::addVariable(const QString& name, const QString& value)
{
    QueryParam param(name, value);

    _variables << param;

    emit variablesChanged();
    emit dataChanged();
}

void GraphqlQuery::addVariable(const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param(name, value, isEnabled);

    _variables << param;

    emit variablesChanged();
    emit dataChanged();
}

void GraphqlQuery::setVariable(int index, const QString& name, const QString& value, bool isEnabled)
{
    QueryParam param = _variables[index];
    param.setName(name);
    param.setValue(value);
    param.setIsEnabled(isEnabled);

    _variables[index] = param;

    emit variablesChanged();
    emit dataChanged();
}

void GraphqlQuery::removeVariable(int index)
{
    _variables.removeAt(index);

    emit variablesChanged();
    emit dataChanged();
}

void GraphqlQuery::removeVariable(const QString& name)
{
    QList<QueryParam> newVariables;
    newVariables.reserve(_variables.size());

    for (QueryParam& header : _variables) {
        if (header.name() == name) {
            continue;
        }

        newVariables << header;
    }

    _variables = newVariables;

    emit variablesChanged();
    emit dataChanged();
}

void GraphqlQuery::fromJson(QJsonObject json)
{
    _queryType = RstEnums::QueryType::GRAPHQL;
    _url = json.value("url").toString("");
    _body = json.value("body").toString("");

    setUuid(json.value("uuid").toString(Util::uuid()));
    setName(json.value("name").toString(""));
    setNodeType(RstEnums::NodeType::GraphqlQueryNode);

    if (json.contains("last_answer")) {
        QJsonObject answerJson = json.value("last_answer").toObject();

        auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
        answer->fromJson(std::move(answerJson));

        _lastAnswer = answer;

        connect(_lastAnswer.get(), &HttpAnswer::bodyChanged, this, &GraphqlQuery::dataChanged);
    }
    else {
        _lastAnswer = QSharedPointer<HttpAnswer>();
    }

    auto paramsArr = json.value("headers").toArray();

    for (QJsonValueRef item : paramsArr) {
        QueryParam param(item.toObject());
        _headers << param;
    }

    auto variablesArr = json.value("variables").toArray();

    for (QJsonValueRef item : variablesArr) {
        QueryParam param(item.toObject());
        _variables << param;
    }
}

QJsonObject GraphqlQuery::toJson() const
{
    QJsonObject json;
    json["uuid"] = uuid();
    json["name"] = name();
    json["url"] = _url;
    json["body"] = _body;
    json["query_type"] = Util::getQueryTypeString(_queryType);
    json["node_type"] = static_cast<int>(RstEnums::NodeType::GraphqlQueryNode);

    if (!_lastAnswer.isNull()) {
        json["last_answer"] = _lastAnswer->toJson();
    }

    QJsonArray headerArray;

    for (const QueryParam& param : _headers) {
        headerArray << param.toJson();
    }

    json["headers"] = headerArray;

    QJsonArray variablesArray;

    for (const QueryParam& param : _variables) {
        variablesArray << param.toJson();
    }

    json["variables"] = variablesArray;

    return json;
}
