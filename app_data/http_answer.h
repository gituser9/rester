#ifndef HTTP_ANSWER_H
#define HTTP_ANSWER_H

#include <QJsonObject>
#include <QObject>
#include <QSet>
#include <QString>
#include <QVariantMap>

#include "../util.h"

class HttpAnswer final : public QObject {

    Q_OBJECT

    Q_PROPERTY(int status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QString body READ body WRITE setBody NOTIFY bodyChanged)
    Q_PROPERTY(QVariantMap headers READ headers WRITE setHeaders NOTIFY headersChanged)
    Q_PROPERTY(long duration READ duration WRITE setDuration NOTIFY durationChanged)
    Q_PROPERTY(long byteCount READ byteCount WRITE setByteCount NOTIFY byteCountChanged)
    Q_PROPERTY(QVariantList cookies READ cookies WRITE setCookies NOTIFY cookiesChanged FINAL)

public:
    explicit HttpAnswer(QObject* parent = nullptr);
    virtual ~HttpAnswer() = default;

    int status() const;
    void setStatus(int newStatus);

    QString body() const;
    void setBody(const QString& newBody);

    QVariantMap headers() const;
    void setHeaders(const QVariantMap& newHeaders);

    long duration() const;
    void setDuration(long newDuration);

    long byteCount() const;
    void setByteCount(long newByteCount);

    void fromJson(QJsonObject&& json);
    QJsonObject toJson() const noexcept;

    QVariantList cookies() const;
    void setCookies(const QVariantList& newCookies);

    Q_INVOKABLE void beautify() noexcept;

signals:
    void statusChanged();
    void bodyChanged();
    void headersChanged();
    void durationChanged();
    void byteCountChanged();
    void cookiesChanged();

private:
    int _status;
    QString _body;
    QVariantMap _headers;
    long _duration;
    long _byteCount;
    QVariantList _cookies;
    const QSet<QString> _cookieFields = {
        "name",
        "expires",
        "path",
        "domain",
        "secure",
        "httponly",
        "samesite",
        "max-age",
    };

    void parseCookie() noexcept;
};

#endif // HTTP_ANSWER_H
