#ifndef HTTP_UTILS_H
#define HTTP_UTILS_H

#include <QString>
#include <QUrl>
#include <QUrlQuery>
#include <QNetworkReply>

#include <zlib.h>
#include <brotli/decode.h>

#include "../util.h"

namespace HttpUtils {

enum class CompressAlg {
    None,
    Gzip,
    Deflate,
    Brotli,
    Unknown
};

inline QString getErrorString(QNetworkReply* reply)
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
    case QNetworkReply::NetworkError::ProtocolFailure:
        return "Protocol Failure";
    default:
        return "";
    }
}

inline CompressAlg isCompressed(const QVariantMap& headers) noexcept
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

inline QByteArray decompressGzip(const QByteArray& compressed) noexcept
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
    zs.next_in = (Bytef*) (compressed.data());
    zs.avail_out = uncompressedData.size();
    zs.next_out = (Bytef*) (uncompressedData.data());

    int status = inflate(&zs, Z_FINISH);

    if (status != Z_STREAM_END) {
        inflateEnd(&zs);

        return compressed;
    }

    inflateEnd(&zs);

    uncompressedData.resize(uncompressedData.size() - zs.avail_out);

    return uncompressedData;
}

inline QByteArray decompressDeflate(const QByteArray& compressed) noexcept
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
    zs.next_in = (Bytef*) (compressed.data());
    zs.avail_out = uncompressedData.size();
    zs.next_out = (Bytef*) (uncompressedData.data());

    int status = inflate(&zs, Z_FINISH);

    if (status != Z_STREAM_END) {
        inflateEnd(&zs);

        return compressed;
    }

    inflateEnd(&zs);

    uncompressedData.resize(uncompressedData.size() - zs.avail_out);

    return uncompressedData;
}

inline QByteArray decompressBrotli(const QByteArray& compressed) noexcept
{
    if (compressed.isEmpty()) {
        return compressed;
    }

    BrotliDecoderState* decoder = BrotliDecoderCreateInstance(nullptr, nullptr, nullptr);

    if (!decoder) {
        return compressed;
    }

    QByteArray result;
    result.reserve(compressed.size() * 3);

    const uint8_t* in_ptr = reinterpret_cast<const uint8_t*>(compressed.constData());
    size_t available_in = static_cast<size_t>(compressed.size());

    constexpr size_t kBufferSize = 16384;
    uint8_t buffer[kBufferSize];

    BrotliDecoderResult brotli_res = BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT;

    while (brotli_res == BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT) {
        uint8_t* out_ptr = buffer;
        size_t available_out = kBufferSize;

        brotli_res = BrotliDecoderDecompressStream(
            decoder,
            &available_in,
            &in_ptr,
            &available_out,
            &out_ptr,
            nullptr //
        );

        if (brotli_res == BROTLI_DECODER_RESULT_ERROR) {
            BrotliDecoderDestroyInstance(decoder);
            return compressed;
        }

        size_t out_size = kBufferSize - available_out;

        if (out_size > 0) {
            result.append(reinterpret_cast<const char*>(buffer), out_size);
        }
    }

    BrotliDecoderDestroyInstance(decoder);

    if (brotli_res != BROTLI_DECODER_RESULT_SUCCESS) {
        return compressed;
    }

    result.squeeze();

    return result;
}

inline QByteArray decompress(const QVariantMap& headers, const QByteArray& body) noexcept
{
    CompressAlg alg = isCompressed(headers);

    switch (alg) {
    case CompressAlg::Gzip:
        return decompressGzip(body);
    case CompressAlg::Deflate:
        return decompressDeflate(body);
    case CompressAlg::Brotli:
        return decompressBrotli(body);
    default:
        return body;
    }

    return body;
}

inline QUrl prepareUrl(const QString& rawUrl, const QVariantList& vars, const QRegularExpression& varRegex, const QList<QueryParam> params = {})
{
    QString urlString = Util::fillVars(rawUrl, vars, varRegex);

    if (urlString.startsWith("localhost")) {
        urlString = urlString.replace("localhost", "http://127.0.0.1");
    }

    QUrl url = urlString;
    QUrlQuery urlParams;

    for (const QueryParam& param : params) {
        if (!param.isEnabled()) {
            continue;
        }

        QString value = Util::fillVars(param.value(), vars, varRegex);
        urlParams.addQueryItem(param.name(), value);
    }

    url.setQuery(urlParams.toString(QUrl::FullyEncoded));

    return url;
}

inline QMap<QByteArray, QByteArray> prepareHeaders(const QVariantList& vars, const QRegularExpression& varRegex, const QList<QueryParam> headers)
{
    QMap<QByteArray, QByteArray> result;

    for (const QueryParam& header : headers) {
        if (!header.isEnabled()) {
            continue;
        }

        QString val = Util::fillVars(header.value(), vars, varRegex);
        result[header.name().toUtf8()] = val.toUtf8();
    }

    return result;
}

} // namespace HttpUtils

#endif // HTTP_UTILS_H
