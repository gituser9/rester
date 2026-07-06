#ifndef GRAPHQL_CLIENT_H
#define GRAPHQL_CLIENT_H

#include <QObject>
#include <QSharedPointer>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "../app_data/constant.h"
#include "../app_data/http_answer.h"
#include "../app_data/graphql_query.h"
#include "../parsers/graphql_parser.h"
#include "http_utils.h"

class GraphqlClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isRequestWork READ isRequestWork WRITE setIsRequestWork NOTIFY isRequestWorkChanged)

public:
    explicit GraphqlClient(QObject* parent = nullptr);

    // Properties
    bool isRequestWork() const;
    void setIsRequestWork(bool newIsRequestWork);

    // Custom
    void makeRequest(GraphqlQuery* query);
    void setVars(const QVariantList& newVars);

    // QML
    Q_INVOKABLE void abortReply();

signals:
    void finished(QSharedPointer<HttpAnswer>);
    void httpError(QString);
    void isRequestWorkChanged();

private slots:
    void slotFinished(QNetworkReply* reply);

private:
    bool _isRequestWork;
    qint64 _startTime;
    QVariantList _vars;
    QRegularExpression _varRegex;
    QNetworkAccessManager* _manager;
    QNetworkReply* _reply;
};

#endif // GRAPHQL_CLIENT_H
