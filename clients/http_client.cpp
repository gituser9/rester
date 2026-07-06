#include "http_client.h"

HttpClient::HttpClient(QObject* parent) :
    QObject{parent},
    _varRegex(RstConstant::varRegexPattern)
{
    _manager = new QNetworkAccessManager(this);
    // _manager->setRedirectPolicy(QNetworkRequest::SameOriginRedirectPolicy);
    _reply = nullptr;
    _isRequestWork = false;
    _varRegex.optimize();

    connect(_manager, &QNetworkAccessManager::finished, this, &HttpClient::slotFinished);
}

void HttpClient::makeRequest(Query* query)
{
    if (query == nullptr) {
        emit httpError("query is empty");

        return;
    }

    setIsRequestWork(true);

    QNetworkRequest request;

    // set content-type
    switch (query->bodyType()) {
    case RstEnums::BodyType::JSON:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=UTF-8");
        break;
    case RstEnums::BodyType::XML:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/xml; charset=UTF-8");
        break;
    case RstEnums::BodyType::MULTIPART_FORM:
        // sets in method with boundary
        break;
    case RstEnums::BodyType::URL_ENCODED_FORM:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
        break;
    default:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "text/plain");
        break;
    }

    // set headers
    auto preparedHeaders = HttpUtils::prepareHeaders(_vars, _varRegex, query->headerList());

    for (auto& k : preparedHeaders.keys()) {
        request.setRawHeader(k, preparedHeaders[k]);
    }

    // set url
    QUrl url = HttpUtils::prepareUrl(query->url(), _vars, _varRegex, query->paramList());
    request.setUrl(url);

    switch (query->bodyType()) {
    case RstEnums::BodyType::MULTIPART_FORM:
        sendMultipartForm(query, request);
        return;
    case RstEnums::BodyType::URL_ENCODED_FORM:
        sendFormUrlEncoded(query, request);
        return;
    default:
        _startTime = std::chrono::steady_clock::now();
        send(query, request);
    }
}

void HttpClient::abortReply()
{
    setIsRequestWork(false);

    if (_reply == nullptr) {
        return;
    }

    _reply->abort();
    _reply->deleteLater();
}

void HttpClient::slotFinished(QNetworkReply* reply)
{
    auto end = std::chrono::steady_clock::now();
    long ms = std::chrono::duration_cast<std::chrono::milliseconds>(end - _startTime).count();

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

    // create answer
    auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
    answer->setStatus(statusCode.toInt());
    answer->setDuration(ms);
    answer->setByteCount(body.size());
    answer->setHeaders(headers);
    answer->setBody(body);
    answer->beautify();

    emit finished(answer);
}

bool HttpClient::isRequestWork() const
{
    return _isRequestWork;
}

void HttpClient::setIsRequestWork(bool newIsRequestWork)
{
    _isRequestWork = newIsRequestWork;
    emit isRequestWorkChanged();
}

void HttpClient::setVars(const QVariantList& newVars)
{
    _vars = newVars;
}

void HttpClient::sendMultipartForm(Query* query, QNetworkRequest request)
{
    auto multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);
    QVariantList formData = query->formData();
    QMimeDatabase mimeDb;

    for (const QVariant& item : formData) {
        QueryParam data(item);

        if (!data.isEnabled()) {
            continue;
        }

        QString fieldName = data.name();
        QString fieldValue = data.value();

        if (fieldValue.startsWith("file://")) {
            // file part
            QString filePath = fieldValue.replace("file://", "");

            if (!QFile::exists(filePath)) {
                continue;
            }

            // mime type
            QMimeType mime = mimeDb.mimeTypeForFile(filePath);
            QString mimeType = mime.name();

            // set file headers
            QHttpPart imagePart;
            QFileInfo info(filePath);

            QString fileHeader = QString(R"(form-data; name="%1"; filename="%2";)").arg(fieldName, info.fileName());
            imagePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(mimeType));
            imagePart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant(fileHeader));

            // prepare file
            auto file = new QFile(filePath);
            file->setParent(multiPart); // we cannot delete the file now, so  delete it with the multiPart

            if (file->open(QIODevice::ReadOnly)) {
                imagePart.setBodyDevice(file);
                multiPart->append(imagePart);
            }
        }
        else {
            // text part
            QString header = QString("form-data; name=\"%1\";").arg(fieldName);

            QHttpPart textPart;
            textPart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant("text/plain"));
            textPart.setHeader(QNetworkRequest::ContentDispositionHeader, QVariant(header));
            textPart.setBody(fieldValue.toUtf8());

            multiPart->append(textPart);
        }
    }

    // set boundary headers
    QString boundary = QVariant(rand()).toString() + QVariant(rand()).toString() + QVariant(rand()).toString();
    multiPart->setBoundary(boundary.toUtf8());

    request.setRawHeader(
        QString("Content-Type").toUtf8(),
        QString("multipart/form-data;boundary=" + boundary).toUtf8());

    _startTime = std::chrono::steady_clock::now();

    send(query, request, multiPart);

    multiPart->setParent(_reply); // delete the multiPart with the reply
}

void HttpClient::sendFormUrlEncoded(Query* query, QNetworkRequest request)
{
    QVariantList formData = query->formData();
    QUrlQuery urlQuery;

    for (const QVariant& item : formData) {
        QueryParam data(item);

        QString fieldName = data.name();
        QString fieldValue = data.value();

        urlQuery.addQueryItem(fieldName, fieldValue);
    }

    _startTime = std::chrono::steady_clock::now();

    send(query, request);
}

void HttpClient::send(Query* query, QNetworkRequest& request)
{
    switch (query->queryType()) {
    case RstEnums::QueryType::GET:
        _reply = _manager->get(request);
        break;
    case RstEnums::QueryType::POST:
        _reply = _manager->post(request, query->body().toUtf8());
        break;
    case RstEnums::QueryType::PUT:
        _reply = _manager->put(request, query->body().toUtf8());
        break;
    case RstEnums::QueryType::PATCH:
        _reply = _manager->sendCustomRequest(request, "PATCH", query->body().toUtf8());
        break;
    case RstEnums::QueryType::DELETE:
        _reply = _manager->deleteResource(request);
        break;
    case RstEnums::QueryType::HEAD:
        _reply = _manager->head(request);
        break;
    case RstEnums::QueryType::WS:
    case RstEnums::QueryType::GRPC:
    case RstEnums::QueryType::GRAPHQL:
        break;
    }
}

void HttpClient::send(Query* query, QNetworkRequest& request, QHttpMultiPart* form)
{
    QString method = Util::getQueryTypeString(query->queryType());
    _reply = _manager->sendCustomRequest(request, method.toUtf8(), form);
}
