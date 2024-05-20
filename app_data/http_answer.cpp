#include "http_answer.h"

HttpAnswer::HttpAnswer(QObject* parent)
    : QObject { parent }
{
    _body = "";
    _status = 0;
    _headers = {};
    _byteCount = 0;
    _duration = 0;
}

long HttpAnswer::byteCount() const
{
    return _byteCount;
}

void HttpAnswer::setByteCount(long newByteCount)
{
    if (_byteCount == newByteCount) {
        return;
    }

    _byteCount = newByteCount;

    emit byteCountChanged();
}

long HttpAnswer::duration() const
{
    return _duration;
}

void HttpAnswer::setDuration(long newDuration)
{
    if (_duration == newDuration) {
        return;
    }

    _duration = newDuration;

    emit durationChanged();
}

QVariantMap HttpAnswer::headers() const
{
    return _headers;
}

void HttpAnswer::setHeaders(const QVariantMap& newHeaders)
{
    if (_headers == newHeaders) {
        return;
    }

    _headers = newHeaders;

    emit headersChanged();

    // cookies
    parseCookie();
}

QString HttpAnswer::body() const
{
    return _body;
}

void HttpAnswer::setBody(const QString& newBody)
{
    if (_body == newBody) {
        return;
    }

    _body = newBody;

    emit bodyChanged();
}

int HttpAnswer::status() const
{
    return _status;
}

void HttpAnswer::setStatus(int newStatus)
{
    if (_status == newStatus) {
        return;
    }

    _status = newStatus;

    emit statusChanged();
}

void HttpAnswer::fromJson(QJsonObject&& json)
{
    _body = json.value("body").toString("");
    _status = json.value("status").toInt();
    _headers = json.value("headers").toObject().toVariantMap();
    _byteCount = json.value("byte_count").toInt(0);
    _duration = json.value("duration").toInteger(0);

    parseCookie();
}

QJsonObject HttpAnswer::toJson() const noexcept
{
    return {
        { "status", _status },
        { "body", _body },
        { "headers", QJsonObject::fromVariantMap(_headers) },
        { "duration", (qint64)_duration },
        { "byte_count", (qint64)_byteCount },
    };
}

void HttpAnswer::beautify() noexcept
{
    setBody(Util::beautify(_body, _headers));
    emit bodyChanged();
}

void HttpAnswer::parseCookie() noexcept
{
    QString cookie = Util::getHeaderValue("Set-Cookie", _headers);

    if (cookie.isEmpty()) {
        return;
    }

    QStringList cookies = cookie.split("\n"); // может быть запятая
    QVariantList cookieList;

    for (const QString& cookieString : cookies) {
        QStringList cookieItems = cookieString.split(";");
        QVariantMap cookieValue;

        for (const QString& cookieItem : cookieItems) {
            QStringList parts = cookieItem.split('=');

            if (parts.isEmpty()) {
                continue;
            }

            QString cookieName = parts[0].trimmed().toLower();

            if (_cookieFields.contains(cookieName)) {
                if (parts.size() == 2) {
                    QString value = parts[1].trimmed();
                    cookieValue[cookieName] = value;
                } else {
                    cookieValue[cookieName] = "";
                }
            } else {
                if (parts.size() == 2) {
                    QString value = parts[1].trimmed();
                    cookieValue[cookieName] = value;
                } else {
                    cookieValue[cookieName] = "";
                }
            }
        }

        cookieList << cookieValue;
    }

    if (!cookieList.isEmpty()) {
        setCookies(cookieList);
    }
}

QVariantList HttpAnswer::cookies() const
{
    return _cookies;
}

void HttpAnswer::setCookies(const QVariantList& newCookies)
{
    if (_cookies == newCookies) {
        return;
    }

    _cookies = newCookies;

    emit cookiesChanged();
}
