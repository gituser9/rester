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
#include <QSharedPointer>
#include <QUrl>
#include <QUrlQuery>
#include <QVariantList>
#include <QMap>
#include <QByteArray>
#include <QRegularExpression>

#include <zlib.h>
#include <brotli/decode.h>

#include "../app_data/constant.h"
#include "../app_data/http_answer.h"
#include "../app_data/query.h"
#include "http_utils.h"

enum class CompressAlg {
    None,
    Gzip,
    Deflate,
    Brotli,
    Unknown
};

class HttpClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isRequestWork READ isRequestWork WRITE setIsRequestWork NOTIFY isRequestWorkChanged)

public:
    explicit HttpClient(QObject* parent = nullptr);

    void makeRequest(Query* query);
    Q_INVOKABLE void abortReply();

    bool isRequestWork() const;
    void setIsRequestWork(bool newIsRequestWork);
    void setVars(const QVariantList& newVars); // TODO: need types

signals:
    void finished(QSharedPointer<HttpAnswer>);
    void httpError(QString);
    void isRequestWorkChanged();

private:
    QNetworkAccessManager* _manager;
    QNetworkReply* _reply;
    QVariantList _vars;
    QRegularExpression _varRegex;
    std::chrono::steady_clock::time_point _startTime;
    bool _isRequestWork;

    void sendMultipartForm(Query* query, QNetworkRequest request);
    void sendFormUrlEncoded(Query* query, QNetworkRequest request);
    void send(Query* query, QNetworkRequest& request);
    void send(Query* query, QNetworkRequest& request, QHttpMultiPart* form);

private slots:
    void slotFinished(QNetworkReply* reply);
};

#endif // HTTPCLIENT_H
