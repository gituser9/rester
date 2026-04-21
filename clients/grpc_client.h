#ifndef GRPC_CLIENT_H
#define GRPC_CLIENT_H

#include <chrono>

#include <QDir>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QObject>
#include <QString>
#include <QList>
#include <QDateTime>
#include <QtConcurrent>
#include <QSharedPointer>

#include <google/protobuf/compiler/importer.h>
#include <google/protobuf/dynamic_message.h>
#include <google/protobuf/util/json_util.h>
#include <grpcpp/generic/generic_stub.h>
#include <grpcpp/grpcpp.h>

#include "../app_data/http_answer.h"
#include "../app_data/grpc_query.h"
#include "../util.h"

// Описание одного RPC-метода
struct RpcMethodInfo {
    QString name;         // "SayHello"
    QString inputType;    // "HelloRequest"
    QString outputType;   // "HelloReply"
    bool clientStreaming; // stream на стороне клиента
    bool serverStreaming; // stream на стороне сервера
};

// Описание одного сервиса из .proto файла
struct ProtoServiceInfo {
    QString packageName; // "helloworld"
    QString serviceName; // "Greeter"
    QList<RpcMethodInfo> methods;
};

class GrpcClient : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool isRequestWork READ isRequestWork WRITE setIsRequestWork NOTIFY isRequestWorkChanged)

public:
    explicit GrpcClient(QObject* parent = nullptr);
    ~GrpcClient() override;

    // Properties
    bool isRequestWork() const;
    void setIsRequestWork(bool newIsRequestWork);

    // Custom
    void call(GrpcQuery* query);
    void setVars(const QVariantList& newVars);
    QList<ProtoServiceInfo> parseProtoFile(const QString& protoFilePath);

signals:
    void requestFinished(QSharedPointer<HttpAnswer>);
    void requestError(const QString& errorMessage);
    void isRequestWorkChanged();

private slots:
    void onCallFinished();

private:
    bool _isRequestWork;
    long long _startTime;
    QVariantList _vars;

    struct CallResult {
        int status;
        bool success;
        QString data;
        QVariantMap meta;
    };

    CallResult performCall(GrpcQuery* query);

    QFutureWatcher<CallResult> _watcher;
};

#endif // GRPC_CLIENT_H
