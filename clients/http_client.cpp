#include "http_client.h"

HttpClient::HttpClient(QObject* parent)
    : QObject { parent }
{
    _manager = new QNetworkAccessManager(this);
    _manager->setRedirectPolicy(QNetworkRequest::SameOriginRedirectPolicy);
    _reply = nullptr;
    _isRequestWork = false;

    _varRegex = QRegularExpression("{{\\s*(.*?)\\s*}}");
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
    case BodyType::JSON:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=UTF-8");
        break;
    case BodyType::XML:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/xml; charset=UTF-8");
        break;
    case BodyType::MULTIPART_FORM:
        // sets in method with boundary
        break;
    case BodyType::URL_ENCODED_FORM:
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
        break;
    default:
        break;
    }

    // set headers
    for (const QueryParam& header : query->headerList()) {
        if (!header.isEnabled()) {
            continue;
        }

        request.setRawHeader(
            header.name().toUtf8(),
            header.value().toUtf8()
        );
    }

    // set url
    QUrl url = prepareUrl(query);
    request.setUrl(url);

    // send forms
    if (query->bodyType() == BodyType::MULTIPART_FORM) {
        sendMultipartForm(query, request);

        return;
    }

    if (query->bodyType() == BodyType::URL_ENCODED_FORM) {
        sendFormUrlEncoded(query, request);

        return;
    }

    // send text body
    _startTime = std::chrono::steady_clock::now();

    send(query, request);
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

    QString errorString = getErrorString(reply);

    if (!errorString.isEmpty()) {
        emit httpError(errorString);

        reply->deleteLater();

        _isRequestWork = false;

        return;
    }

    reply->deleteLater();
    QVariant statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute);
    QByteArray body = reply->readAll();

    // headers
    QList<QByteArray> rawHeaders = reply->rawHeaderList();
    QVariantMap headers;

    for (const QByteArray& header : rawHeaders) {
        headers[header] = QString(reply->rawHeader(header));
    }

    // body
    auto alg = isCompressed(headers);

    if (alg != CompressAlg::None) {
        body = uncompress(body, alg);
    }

    // create answer
    auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
    answer->setStatus(statusCode.toInt());
    answer->setDuration(ms);
    answer->setByteCount(body.size());

    answer->setHeaders(headers);

    auto bbody = Util::beautify(body, headers);
    answer->setBody(bbody);

    emit finished(answer);
}

bool HttpClient::isRequestWork() const { return _isRequestWork; }

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

            // check exists
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
        } else {
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

void HttpClient::send(Query* query, QNetworkRequest& request) noexcept
{
    switch (query->queryType()) {
    case QueryType::GET:
        _reply = _manager->get(request);
        break;
    case QueryType::POST:
        _reply = _manager->post(request, query->body().toUtf8());
        break;
    case QueryType::PUT:
        _reply = _manager->put(request, query->body().toUtf8());
        break;
    case QueryType::PATCH:
        _reply = _manager->sendCustomRequest(request, "PATCH", query->body().toUtf8());
        break;
    case QueryType::DELETE:
        _reply = _manager->deleteResource(request);
        break;
    case QueryType::HEAD:
        _reply = _manager->head(request);
        break;
    }
}

void HttpClient::send(Query* query, QNetworkRequest& request, QHttpMultiPart* form) noexcept
{
    QString method = Util::getQueryTypeString(query->queryType());
    _reply = _manager->sendCustomRequest(request, method.toUtf8(), form);
}

CompressAlg HttpClient::isCompressed(const QVariantMap& headers) const noexcept
{
    QString compress = headers["Content-Encoding"].toString();

    if (compress.isEmpty()) {
        compress = headers["content-encoding"].toString();

        if (compress.isEmpty()) {
            return CompressAlg::None;
        }
    }

    if (compress.contains("zip")) {
        return CompressAlg::Gzip;
    }

    if (compress.contains("deflate")) {
        return CompressAlg::Deflate;
    }

    if (compress.contains("br")) {
        return CompressAlg::Brotli;
    }

    return CompressAlg::Unknown;
}

QString HttpClient::getErrorString(QNetworkReply* reply)
{
    auto error = reply->error();

    switch (error) {
    // network layer errors [relating to the destination server]
    case QNetworkReply::NetworkError::ConnectionRefusedError:
        return "Connection Refused Error";
    case QNetworkReply::NetworkError::RemoteHostClosedError:
        return "Remote Host Closed Error";
    case QNetworkReply::NetworkError::HostNotFoundError:
        return "Host Not Found Error";
    case QNetworkReply::NetworkError::TimeoutError:
        return "Timeout Error";
    case QNetworkReply::NetworkError::OperationCanceledError:
        return "Operation Canceled Error";
    case QNetworkReply::NetworkError::SslHandshakeFailedError:
        return "Ssl Handshake Failed Error";
    case QNetworkReply::NetworkError::TemporaryNetworkFailureError:
        return "Temporary Network Failure Error";
    case QNetworkReply::NetworkError::NetworkSessionFailedError:
        return "Network Session Failed Error";
    case QNetworkReply::NetworkError::BackgroundRequestNotAllowedError:
        return "Background Request Not Allowed Error";
    case QNetworkReply::NetworkError::TooManyRedirectsError:
        return "Too Many Redirects Error";
    case QNetworkReply::NetworkError::InsecureRedirectError:
        return "Insecure Redirect Error";
    case QNetworkReply::NetworkError::UnknownNetworkError:
        return "Unknown Network Error";

    // proxy errors
    case QNetworkReply::NetworkError::ProxyConnectionRefusedError:
        return "Proxy Connection Refused Error";
    case QNetworkReply::NetworkError::ProxyConnectionClosedError:
        return "Proxy Connection Closed Error";
    case QNetworkReply::NetworkError::ProxyNotFoundError:
        return "Proxy Not Found Error";
    case QNetworkReply::NetworkError::ProxyTimeoutError:
        return "Proxy Timeout Error";
    case QNetworkReply::NetworkError::ProxyAuthenticationRequiredError:
        return "Proxy Authentication Required Error";
    case QNetworkReply::NetworkError::UnknownProxyError:
        return "Unknown Proxy Error";

    // protocol errors
    case QNetworkReply::NetworkError::ProtocolUnknownError:
        return "Protocol Unknown Error";
    case QNetworkReply::NetworkError::ProtocolInvalidOperationError:
        return "Protocol Invalid Operation Error";
    case QNetworkReply::NetworkError::ProtocolFailure:
        return "Protocol Failure";
    default:
        return "";
    }
}

QUrl HttpClient::prepareUrl(Query* query) const noexcept
{
    QString urlString = query->url();

    if (!_vars.isEmpty()) {
        QRegularExpressionMatchIterator iter = _varRegex.globalMatch(urlString);

        while (iter.hasNext()) {
            QRegularExpressionMatch match = iter.next();
            QString variable = match.captured(1).trimmed();

            for (auto& var : _vars) {
                QVariantMap varMap = var.toMap();

                if (varMap["name"] == variable) {
                    urlString = urlString.replace("{{" + variable + "}}", varMap["value"].toString());
                }
            }
        }
    }

    QUrl url = urlString;
    QUrlQuery urlParams;

    for (const QueryParam& param : query->paramList()) {
        if (!param.isEnabled()) {
            continue;
        }

        urlParams.addQueryItem(param.name(), param.value());
    }

    url.setQuery(urlParams.toString(QUrl::FullyEncoded));

    return url;
}

QByteArray HttpClient::uncompress(const QByteArray& compressed, CompressAlg alg) const noexcept
{
    switch (alg) {
    case CompressAlg::Gzip:
        return uncompressGzip(compressed);
    case CompressAlg::Deflate:
        return uncompressDeflate(compressed);
    case CompressAlg::Brotli:
        return compressed;
    default:
        return compressed;
    }

    return compressed;
}

QByteArray HttpClient::uncompressGzip(const QByteArray& compressed) const noexcept
{
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    if (inflateInit2(&zs, 47) != Z_OK) {
        return compressed;
    }

    // create buffer for unpack data
    QByteArray uncompressedData;
    // uncompressedData.resize(16384);
    uncompressedData.resize(compressed.size() * 60);

    zs.avail_in = compressed.size();
    zs.next_in = (Bytef*)(compressed.data());
    zs.avail_out = uncompressedData.size();
    zs.next_out = (Bytef*)(uncompressedData.data());

    int status = inflate(&zs, Z_FINISH);

    if (status != Z_STREAM_END) {
        inflateEnd(&zs);

        return compressed;
    }

    inflateEnd(&zs);

    uncompressedData.resize(uncompressedData.size() - zs.avail_out);
    return uncompressedData;
}

QByteArray HttpClient::uncompressDeflate(const QByteArray& compressed) const noexcept
{
    // set zlib param for unpack deflate
    z_stream zs;
    memset(&zs, 0, sizeof(zs));
    if (inflateInit(&zs) != Z_OK) {

        return compressed;
    }

    // create buffer for unpack data
    QByteArray uncompressedData;
    uncompressedData.resize(16384); // begin size

    zs.avail_in = compressed.size();
    zs.next_in = (Bytef*)(compressed.data());
    zs.avail_out = uncompressedData.size();
    zs.next_out = (Bytef*)(uncompressedData.data());

    int status = inflate(&zs, Z_FINISH);
    if (status != Z_STREAM_END) {
        inflateEnd(&zs);

        return compressed;
    }

    inflateEnd(&zs);

    uncompressedData.resize(uncompressedData.size() - zs.avail_out);

    return uncompressedData;
}
