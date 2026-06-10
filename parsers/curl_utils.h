#ifndef CURL_UTILS_H
#define CURL_UTILS_H

#include <QList>
#include <QUrl>
#include <QUrlQuery>

#include "../app_data/query_param.h"
#include "../util.h"

namespace CurlUtils {

inline QString buildUrl(const QString& rawUrl, const QVariantList& envVars, QList<QueryParam> params = {})
{
    QUrl url = Util::fillVars(rawUrl, envVars);
    QUrlQuery urlParams;

    for (const QueryParam& param : params) {
        if (!param.isEnabled()) {
            continue;
        }

        QString value = Util::fillVars(param.value(), envVars);
        urlParams.addQueryItem(param.name(), value);
    }

    url.setQuery(urlParams.toString(QUrl::FullyEncoded));

    return url.toString();
}

inline QString escapeBody(const QString& body)
{
    QString escapedBody = body;
    escapedBody = escapedBody.replace("'", "'\\''");

    return escapedBody;
}

inline QString buildHeaders(const QList<QueryParam>& headers, const QVariantList& envVars)
{
    QString headerString;

    for (const QueryParam& header : headers) {
        if (!header.isEnabled()) {
            continue;
        }

        QString value = Util::fillVars(header.value(), envVars);
        headerString += "  --header '" + header.name() + ": " + value + "' \\" + "\n";
    }

    return headerString;
}

} // namespace CurlUtils

#endif // CURL_UTILS_H
