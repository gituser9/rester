#include "grpc_query.h"

GrpcQuery::GrpcQuery(TreeNode* parent) :
    TreeNode(parent)
{
    _queryType = QueryType::GRPC;
    setNodeType(NodeType::GrpcQueryNode);
}

GrpcQuery::~GrpcQuery()
{
}

QueryType GrpcQuery::queryType() const
{
    return _queryType;
}

QString GrpcQuery::url() const
{
    return _url;
}

void GrpcQuery::setUrl(const QString& newUrl)
{
    if (_url == newUrl) {
        return;
    }

    _url = newUrl;

    emit urlChanged();
    emit dataChanged();
}

QString GrpcQuery::rpc() const
{
    return _rpc;
}

void GrpcQuery::setRpc(const QString& newRpc)
{
    if (_rpc == newRpc) {
        return;
    }

    _rpc = newRpc;

    emit rpcChanged();
    emit metaChanged();
    emit bodyChanged();
    emit lastAnswerChanged();
    emit dataChanged();
}

QStringList GrpcQuery::availableRpc() const
{
    return _availableRpc.value(_srv);
}

void GrpcQuery::setAvailableRpc(const QMap<QString, QStringList>& newRpc)
{
    _availableRpc = newRpc;

    emit availableRpcChanged();
    emit dataChanged();
}

QString GrpcQuery::srv() const
{
    return _srv;
}

void GrpcQuery::setSrv(const QString& newSrv)
{
    if (_srv == newSrv) {
        return;
    }

    _srv = newSrv;

    emit srvChanged();
    emit dataChanged();
}

QStringList GrpcQuery::availableSrv() const
{
    return _availableSrv;
}

void GrpcQuery::setAvailableSrv(const QStringList& newSrvs)
{
    _availableSrv = newSrvs;

    emit availableSrvChanged();
    emit dataChanged();
}

QVariantList GrpcQuery::meta() const
{
    auto meta = _availableMeta.value(_rpc);
    QVariantList list;
    list.reserve(meta.count());

    for (const QueryParam& item : meta) {
        list << QVariant::fromValue(item);
    }

    return list;
}

QList<QueryParam> GrpcQuery::metaList() const
{
    return _availableMeta.value(_rpc);
}

void GrpcQuery::setMeta(const QVariantList& newMeta)
{
    auto meta = _availableMeta.value(_rpc);
    meta.clear();

    for (const QVariant& item : newMeta) {
        QVariantMap map = item.toMap();

        meta << QueryParam(map);
    }

    _availableMeta[_rpc] = meta;

    emit metaChanged();
    emit dataChanged();
}

void GrpcQuery::setMeta(const QList<QueryParam>& newMeta)
{
    _availableMeta[_rpc] = newMeta;

    emit metaChanged();
    emit dataChanged();
}

HttpAnswer* GrpcQuery::lastAnswer() const
{
    auto answer = _availableLastAnswer.value(_rpc);
    if (answer.isNull()) {
        return nullptr;
    }

    return answer.get();
}

void GrpcQuery::setLastAnswer(HttpAnswer* newLastAnswer)
{
    auto answer = _availableLastAnswer.value(_rpc);

    if (!answer.isNull()) {
        disconnect(answer.get(), &HttpAnswer::bodyChanged, this, &GrpcQuery::dataChanged);
        answer.reset();
    }

    if (newLastAnswer != nullptr) {
        answer = QSharedPointer<HttpAnswer>(newLastAnswer);

        connect(answer.get(), &HttpAnswer::bodyChanged, this, &GrpcQuery::dataChanged);
    }

    _availableLastAnswer[_rpc] = answer;

    emit lastAnswerChanged();
    emit dataChanged();
}

void GrpcQuery::setAnswer(QSharedPointer<HttpAnswer> ptr)
{
    auto answer = _availableLastAnswer.value(_rpc);

    if (!answer.isNull()) {
        disconnect(answer.get(), &HttpAnswer::bodyChanged, this, &GrpcQuery::dataChanged);
        answer.reset();
    }

    answer = ptr;

    if (!answer.isNull()) {
        connect(answer.get(), &HttpAnswer::bodyChanged, this, &GrpcQuery::dataChanged);
    }

    _availableLastAnswer[_rpc] = answer;

    emit lastAnswerChanged();
    emit dataChanged();
}

void GrpcQuery::setMetaItem(int index, const QString& name, const QString& value, bool isEnabled)
{
    auto meta = _availableMeta.value(_rpc);

    QueryParam param;

    if (index < 0 || index >= meta.size()) {
        return;
    }

    param.setName(name);
    param.setValue(value);
    param.setIsEnabled(isEnabled);

    meta[index] = param;
    _availableMeta[_rpc] = meta;

    emit metaChanged();
    emit dataChanged();
}

void GrpcQuery::removeMetaItem(int index)
{
    auto meta = _availableMeta.value(_rpc);

    if (index < 0 || index >= meta.size()) {
        return;
    }

    meta.removeAt(index);
    _availableMeta[_rpc] = meta;

    emit metaChanged();
    emit dataChanged();
}

void GrpcQuery::addMetaItem(const QString& name, const QString& value)
{
    QueryParam param(name, value);
    auto meta = _availableMeta.value(_rpc);

    meta << param;
    _availableMeta[_rpc] = meta;

    emit metaChanged();
    emit dataChanged();
}

void GrpcQuery::fromJson(QJsonObject json)
{
    _queryType = QueryType::GRPC;
    _url = json.value("url").toString();
    _srv = json.value("srv").toString();
    _rpc = json.value("rpc").toString();
    _filePath = json.value("file_path").toString();
    _package = json.value("package").toString();

    setUuid(json.value("uuid").toString(Util::uuid()));
    setName(json.value("name").toString(""));
    setNodeType(NodeType::GrpcQueryNode);

    QJsonObject lastAnswerAvailable = json.value("available_last_answers").toObject();

    for (const QString& rpc : lastAnswerAvailable.keys()) {
        auto answRef = lastAnswerAvailable[rpc];

        if (answRef.isNull()) {
            continue;
        }

        auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
        answer->fromJson(std::move(answRef.toObject()));
        _availableLastAnswer[rpc] = answer;
    }

    auto srvArr = json.value("available_srv").toArray();

    for (QJsonValueRef item : srvArr) {
        _availableSrv << item.toString("");
    }

    QJsonObject rpcAvailable = json.value("available_rpc").toObject();

    for (const QString& srv : rpcAvailable.keys()) {
        QJsonArray jsonRpcArr = rpcAvailable.value(srv).toArray();
        QStringList rpc;

        for (const QJsonValue& arrItem : jsonRpcArr) {
            rpc << arrItem.toString("");
        }

        _availableRpc[srv] = rpc;
    }

    QJsonObject metaAvailable = json.value("available_meta").toObject();

    for (const QString& method : metaAvailable.keys()) {
        QJsonArray jsonRpcArr = metaAvailable.value(method).toArray();
        QList<QueryParam> metaList;

        for (const QJsonValue& arrItem : jsonRpcArr) {
            metaList << QueryParam(arrItem.toObject());
        }

        _availableMeta[method] = metaList;
    }

    QJsonObject bodyAvailable = json.value("available_body").toObject();

    for (const QString& key : bodyAvailable.keys()) {
        _availableBody[key] = bodyAvailable.value(key).toString();
    }
}

QJsonObject GrpcQuery::toJson() const
{
    QJsonObject json;
    json["uuid"] = uuid();
    json["name"] = name();
    json["query_type"] = Util::getQueryTypeString(_queryType);
    json["node_type"] = NodeType::GrpcQueryNode;
    json["url"] = _url;
    json["srv"] = _srv;
    json["rpc"] = _rpc;
    json["file_path"] = _filePath;
    json["package"] = _package;

    QJsonObject availableLastAnswerMap;
    QMapIterator<QString, QSharedPointer<HttpAnswer>> answerIter(_availableLastAnswer);

    while (answerIter.hasNext()) {
        answerIter.next();

        if (answerIter.value().isNull()) {
            continue;
        }

        availableLastAnswerMap[answerIter.key()] = answerIter.value()->toJson();
    }

    json["available_last_answers"] = availableLastAnswerMap;

    QJsonArray availableSrvArray;

    for (const QString& param : _availableSrv) {
        availableSrvArray << param;
    }

    json["available_srv"] = availableSrvArray;

    QJsonObject availableRpcMap;
    QMapIterator iter(_availableRpc);

    while (iter.hasNext()) {
        iter.next();

        QJsonArray rpcArray;

        for (auto& param : iter.value()) {
            rpcArray << param;
        }

        availableRpcMap[iter.key()] = rpcArray;
    }

    json["available_rpc"] = availableRpcMap;

    QJsonObject availableMetaMap;
    QMapIterator metaIter(_availableMeta);

    while (metaIter.hasNext()) {
        metaIter.next();

        QJsonArray metaArray;

        for (auto& param : metaIter.value()) {
            metaArray << param.toJson();
        }

        availableMetaMap[metaIter.key()] = metaArray;
    }

    json["available_meta"] = availableMetaMap;

    QJsonObject availableBodyMap;
    QMapIterator<QString, QString> bodyIter(_availableBody);

    while (bodyIter.hasNext()) {
        bodyIter.next();
        availableBodyMap[bodyIter.key()] = bodyIter.value();
    }

    json["available_body"] = availableBodyMap;

    return json;
}

QString GrpcQuery::body() const
{
    return _availableBody.value(_rpc);
}

void GrpcQuery::setBody(const QString& newBody)
{
    QString cleanBody = newBody;
    _availableBody[_rpc] = cleanBody.replace("&quot;", "\"");

    emit bodyChanged();
    emit dataChanged();
}

QString GrpcQuery::package() const
{
    return _package;
}

void GrpcQuery::setPackage(const QString& newPackage)
{
    if (_package == newPackage) {
        return;
    }

    _package = newPackage;

    emit packageChanged();
    emit dataChanged();
}

QString GrpcQuery::filePath() const
{
    return _filePath;
}

void GrpcQuery::setFilePath(const QString& newFilePath)
{
    if (_filePath == newFilePath) {
        return;
    }

    _filePath = newFilePath;

    emit filePathChanged();
    emit dataChanged();
}
