#ifndef HTTPCLIENT_H
#define HTTPCLIENT_H

#include <chrono>
#include <random>

#include <QFile>
#include <QFileInfo>
#include <QHttpMultiPart>
#include <QMimeDatabase>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QRegularExpression>
#include <QSharedPointer>
#include <QUrl>
#include <QUrlQuery>
#include <QVariantList>
#include <zlib.h>

#include "../app_data/http_answer.h"
#include "../app_data/query.h"

enum class CompressAlg {
    None,
    Gzip,
    Deflate,
    Brotli,
    Unknown
};

class HttpClient : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool isRequestWork READ isRequestWork WRITE setIsRequestWork NOTIFY isRequestWorkChanged)

public:
    explicit HttpClient(QObject* parent = nullptr);

    Q_INVOKABLE void makeRequest(Query* query);
    Q_INVOKABLE void abortReply();

    bool isRequestWork() const;
    void setIsRequestWork(bool newIsRequestWork);
    void setVars(const QVariantList& newVars);

signals:
    void finished(QSharedPointer<HttpAnswer>);
    void httpError(QString);
    void isRequestWorkChanged();

private:
    QNetworkAccessManager* _manager;
    QNetworkReply* _reply;
    QRegularExpression _varRegex;
    QVariantList _vars;
    std::chrono::steady_clock::time_point _startTime;
    bool _isRequestWork;

    void sendMultipartForm(Query* query, QNetworkRequest request);
    void sendFormUrlEncoded(Query* query, QNetworkRequest request);
    void send(Query* query, QNetworkRequest& request) noexcept;
    void send(Query* query, QNetworkRequest& request, QHttpMultiPart* form) noexcept;
    CompressAlg isCompressed(const QVariantMap& headers) const noexcept;
    QString getErrorString(QNetworkReply* reply);
    QUrl prepareUrl(Query* query) const noexcept;
    QByteArray uncompress(const QByteArray& compressed, CompressAlg alg) const noexcept;
    QByteArray uncompressGzip(const QByteArray& compressed) const noexcept;
    QByteArray uncompressDeflate(const QByteArray& compressed) const noexcept;

private slots:
    void slotFinished(QNetworkReply* reply);
};

#endif // HTTPCLIENT_H
