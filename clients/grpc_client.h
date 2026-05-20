#ifndef GRPC_CLIENT_H
#define GRPC_CLIENT_H

#include <memory>
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

struct RpcMethodInfo {
    QString name;
    QString inputType;
    QString outputType;
    bool clientStreaming;
    bool serverStreaming;
};

struct ProtoServiceInfo {
    QString packageName;
    QString serviceName;
    QList<RpcMethodInfo> methods;
};

struct CallResult {
    int status;
    bool success;
    QString data;
    QVariantMap meta;
};

class GrpcClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool isRequestWork READ isRequestWork WRITE setIsRequestWork NOTIFY isRequestWorkChanged)

public:
    explicit GrpcClient(QObject* parent = nullptr);
    ~GrpcClient() override;

    // Properties
    bool isRequestWork() const;
    void setIsRequestWork(bool newIsRequestWork);

    // QML
    Q_INVOKABLE QString generateBody(GrpcQuery* query);

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
    bool _isRequestWork = false;
    qint64 _startTime = 0;
    std::unique_ptr<google::protobuf::DescriptorPool> _pool = nullptr;
    std::unique_ptr<google::protobuf::DynamicMessageFactory> _factory = nullptr;
    std::unique_ptr<google::protobuf::compiler::Importer> _importer = nullptr;
    QVariantList _vars = {};
    QFutureWatcher<CallResult> _watcher;

    CallResult performCall(GrpcQuery* query);
    const google::protobuf::MethodDescriptor* descriptor(GrpcQuery* query, const QString& fullMethodName);
};

#endif // GRPC_CLIENT_H
