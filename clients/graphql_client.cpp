#include "graphql_client.h"

GraphqlClient::GraphqlClient(QObject* parent) :
    QObject{parent},
    _varRegex("{{\\s*(.*?)\\s*}}") // TODO: to const
{
    _manager = new QNetworkAccessManager(this);
    _reply = nullptr;
    _isRequestWork = false;
    _varRegex.optimize();

    connect(_manager, &QNetworkAccessManager::finished, this, &GraphqlClient::slotFinished);
}

bool GraphqlClient::isRequestWork() const
{
    return _isRequestWork;
}

void GraphqlClient::setIsRequestWork(bool newIsRequestWork)
{
    if (_isRequestWork == newIsRequestWork) {
        return;
    }

    _isRequestWork = newIsRequestWork;

    emit isRequestWorkChanged();
}

void GraphqlClient::makeRequest(GraphqlQuery* query)
{
    if (query == nullptr) {
        emit httpError("query is empty");

        return;
    }

    setIsRequestWork(true);

    QNetworkRequest request;

    // set headers
    auto preparedHeaders = HttpUtils::prepareHeaders(_vars, _varRegex, query->headerList());

    for (auto& k : preparedHeaders.keys()) {
        request.setRawHeader(k, preparedHeaders[k]);
    }

    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // set url
    QUrl url = HttpUtils::prepareUrl(query->url(), _vars, _varRegex);
    request.setUrl(url);

    // body
    auto result = GraphqlParser::parse(query->body(), query->variablesList());

    if (!result.isValid) {
        emit httpError("invalid body");
        return;
    }

    // send
    _startTime = QDateTime::currentMSecsSinceEpoch();
    _reply = _manager->post(request, result.requestPayload);
}

void GraphqlClient::setVars(const QVariantList& newVars)
{
    _vars = newVars;
}

void GraphqlClient::abortReply()
{
    setIsRequestWork(false);

    if (_reply == nullptr) {
        return;
    }

    _reply->abort();
    _reply->deleteLater();
}

void GraphqlClient::slotFinished(QNetworkReply* reply)
{
    qint64 end = QDateTime::currentMSecsSinceEpoch();
    qint64 ms = end - _startTime;

    if (reply == nullptr) {
        emit httpError("reply is null");

        return;
    }

    QString errorString = HttpUtils::getErrorString(reply);

    if (!errorString.isEmpty()) {
        emit httpError(errorString);

        _isRequestWork = false;

        return;
    }

    QVariant statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    QByteArray body = reply->readAll();

    // headers
    QList<QByteArray> rawHeaders = reply->rawHeaderList();
    QVariantMap headers;

    for (const QByteArray& header : rawHeaders) {
        headers[header] = QString(reply->rawHeader(header));
    }

    reply->deleteLater();

    // body
    body = HttpUtils::decompress(headers, body);

    // answer
    auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
    answer->setStatus(statusCode.toInt());
    answer->setDuration(ms);
    answer->setByteCount(body.size());
    answer->setHeaders(headers);
    answer->setBody(body);
    answer->beautify();

    emit finished(answer);
}
