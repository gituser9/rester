#include "grpc_client.h"

using namespace google::protobuf;

// error collector for .proto
class ProtoErrorCollector : public compiler::MultiFileErrorCollector
{
public:
    void RecordError(std::string_view filename, int line, int column, std::string_view message) override
    {
        errors += QString("File %1:%2:%3 - %4\n")
                      .arg(filename.data())
                      .arg(line)
                      .arg(column)
                      .arg(message.data());
    }
    QString errors;
};

// Message -> ByteBuffer
static grpc::ByteBuffer SerializeToByteBuffer(const Message* msg)
{
    std::string serializedStr;
    msg->SerializeToString(&serializedStr);
    grpc::Slice slice(serializedStr);

    return {&slice, 1};
}

// ByteBuffer -> Message
static bool ParseFromByteBuffer(grpc::ByteBuffer* buffer, Message* msg)
{
    std::vector<grpc::Slice> slices;
    buffer->Dump(&slices);
    std::string serializedStr;

    for (const auto& slice : slices) {
        serializedStr.append(reinterpret_cast<const char*>(slice.begin()), slice.size());
    }

    return msg->ParseFromString(serializedStr);
}

GrpcClient::GrpcClient(QObject* parent) : QObject{parent}
{
    connect(&_watcher, &QFutureWatcher<CallResult>::finished, this, &GrpcClient::onCallFinished);
}

GrpcClient::~GrpcClient()
{
    if (_watcher.isRunning()) {
        _watcher.cancel();
        _watcher.waitForFinished();
    }
}

bool GrpcClient::isRequestWork() const
{
    return _isRequestWork;
}

void GrpcClient::setIsRequestWork(bool newIsRequestWork)
{
    _isRequestWork = newIsRequestWork;
    emit isRequestWorkChanged();
}

QString GrpcClient::generateBody(GrpcQuery* query)
{
    QString fullMethodName = QStringLiteral("%1.%2.%3")
                                 .arg(query->package())
                                 .arg(query->srv())
                                 .arg(query->rpc());
    const MethodDescriptor* methodDesc = descriptor(query, fullMethodName);

    if (!methodDesc) {
        return "{}";
    }

    std::unique_ptr<Message> requestMsg(_factory->GetPrototype(methodDesc->input_type())->New());

    std::string jsonResponseStr;
    util::JsonPrintOptions printOptions;
    printOptions.always_print_fields_with_no_presence = true;

    auto printStatus = util::MessageToJsonString(*requestMsg, &jsonResponseStr, printOptions);

    if (!printStatus.ok()) {
        return "{}";
    }

    return Util::beautify(QString::fromStdString(jsonResponseStr), BodyType::JSON);
}

void GrpcClient::call(GrpcQuery* query)
{
    if (_watcher.isRunning()) {
        return;
    }

    setIsRequestWork(true);

    QFuture<CallResult> future = QtConcurrent::run(
        [this, query]() {
            return performCall(query);
        });
    _watcher.setFuture(future);
}

CallResult GrpcClient::performCall(GrpcQuery* query)
{
    CallResult result{
        .status = 0,
        .success = false,
        .data = "",
        .meta = {} //
    };

    // handle proto
    QString fullMethodName = QStringLiteral("%1.%2.%3")
                                 .arg(query->package())
                                 .arg(query->srv())
                                 .arg(query->rpc());
    const MethodDescriptor* methodDesc = descriptor(query, fullMethodName);

    if (!methodDesc) {
        result.data = "Method " + fullMethodName + " not found.";
        return result;
    }

    // message
    std::unique_ptr<Message> requestMsg(_factory->GetPrototype(methodDesc->input_type())->New());
    std::unique_ptr<Message> responseMsg(_factory->GetPrototype(methodDesc->output_type())->New());

    // JSON payload to Protobuf Message
    std::string jsonBody = query->body().toStdString();

    if (jsonBody.empty()) {
        jsonBody = "{}";
    }

    util::JsonParseOptions options;
    options.ignore_unknown_fields = true;
    auto jsonStatus = util::JsonStringToMessage(jsonBody, requestMsg.get(), options);

    if (!jsonStatus.ok()) {
        result.data = "Parse JSON payload error: " + QString::fromStdString(std::string(jsonStatus.message()));
        return result;
    }

    // prepare gRPC
    QString url = Util::fillVars(query->url(), _vars);
    std::shared_ptr<grpc::Channel> channel = grpc::CreateChannel(url.toStdString(), grpc::InsecureChannelCredentials());

    grpc::GenericStub stub(channel);
    grpc::ClientContext context;

    // timeout
    context.set_deadline(std::chrono::system_clock::now() + std::chrono::seconds(10));

    // request meta
    QMap<QString, QString> meta;

    for (const auto& item : query->metaList()) {
        if (!item.isEnabled()) {
            continue;
        }

        if (item.name().isEmpty()) {
            continue;
        }

        meta[item.name()] = item.value();
    }

    for (auto it = meta.cbegin(); it != meta.cend(); ++it) {
        QString val = Util::fillVars(it.value(), _vars);

        context.AddMetadata(
            it.key().toLower().toStdString(),
            val.toStdString() //
        );
    }

    // call
    grpc::ByteBuffer responseBuffer;
    grpc::ByteBuffer requestBuffer = SerializeToByteBuffer(requestMsg.get());
    std::string grpcMethodUrl = "/" + methodDesc->service()->full_name() + "/" + methodDesc->name();

    grpc::CompletionQueue cq;
    grpc::Status status;

    _startTime = QDateTime::currentMSecsSinceEpoch();

    std::unique_ptr<grpc::ClientAsyncResponseReader<grpc::ByteBuffer>> rpc(
        stub.PrepareUnaryCall(&context, grpcMethodUrl, requestBuffer, &cq) //
    );
    rpc->StartCall();
    rpc->Finish(&responseBuffer, &status, reinterpret_cast<void*>(1));

    void* gotTag = nullptr;
    bool ok = false;

    // block (timeout in context.set_deadline)
    cq.Next(&gotTag, &ok);

    if (!status.ok()) {
        result.status = static_cast<int>(status.error_code());
        result.data = QString("gRPC error [%1]: %2")
                          .arg(status.error_code())
                          .arg(QString::fromStdString(status.error_message()));
        return result;
    }

    // response meta
    // TODO: handle base64 (-bin trailing keys)
    for (const auto& [key, value] : context.GetServerInitialMetadata()) {
        result.meta[QString::fromStdString(key.data())] = QString::fromStdString(value.data());
    }

    // message to JSON
    if (!ParseFromByteBuffer(&responseBuffer, responseMsg.get())) {
        result.data = "Deserialize error.";
        return result;
    }

    std::string jsonResponseStr;
    util::JsonPrintOptions printOptions;

    auto printStatus = util::MessageToJsonString(*responseMsg, &jsonResponseStr, printOptions);

    if (!printStatus.ok()) {
        result.data = "Convert response to JSON error.";
        return result;
    }

    result.success = true;
    result.data = QString::fromStdString(jsonResponseStr);

    return result;
}

void GrpcClient::setVars(const QVariantList& newVars)
{
    _vars = newVars;
}

QList<ProtoServiceInfo> GrpcClient::parseProtoFile(const QString& protoFilePath)
{
    QFileInfo fileInfo(protoFilePath);

    if (!fileInfo.exists()) {
        emit requestError("Proto файл не найден: " + protoFilePath);
        return {};
    }

    compiler::DiskSourceTree sourceTree;
    sourceTree.MapPath("", fileInfo.absolutePath().toStdString());

    ProtoErrorCollector errCollector;
    compiler::Importer importer(&sourceTree, &errCollector);

    const FileDescriptor* fileDesc = importer.Import(fileInfo.fileName().toStdString());

    if (!fileDesc) {
        emit requestError("Parse error Proto:\n" + errCollector.errors);
        return {};
    }

    const QString packageName = QString::fromStdString(fileDesc->package());

    QList<ProtoServiceInfo> services;
    services.reserve(fileDesc->service_count());

    for (int si = 0; si < fileDesc->service_count(); ++si) {
        const ServiceDescriptor* svcDesc = fileDesc->service(si);

        ProtoServiceInfo svcInfo;
        svcInfo.packageName = packageName;
        svcInfo.serviceName = QString::fromStdString(svcDesc->name());
        svcInfo.methods.reserve(svcDesc->method_count());

        for (int mi = 0; mi < svcDesc->method_count(); ++mi) {
            const MethodDescriptor* methodDesc = svcDesc->method(mi);

            RpcMethodInfo methodInfo;
            methodInfo.name = QString::fromStdString(methodDesc->name());
            methodInfo.inputType = QString::fromStdString(methodDesc->input_type()->name());
            methodInfo.outputType = QString::fromStdString(methodDesc->output_type()->name());
            methodInfo.clientStreaming = methodDesc->client_streaming();
            methodInfo.serverStreaming = methodDesc->server_streaming();

            svcInfo.methods.append(std::move(methodInfo));
        }

        services.append(std::move(svcInfo));
    }

    return services;
}

void GrpcClient::onCallFinished()
{
    qint64 ms = QDateTime::currentMSecsSinceEpoch() - _startTime;
    CallResult result = _watcher.result();

    if (result.success) {
        auto answer = QSharedPointer<HttpAnswer>(new HttpAnswer);
        answer->setDuration(ms);
        answer->setBody(Util::beautify(result.data, BodyType::JSON));
        answer->setByteCount(result.data.size());
        answer->setStatus(result.status);
        answer->setHeaders(result.meta);

        emit requestFinished(answer);
    }
    else {
        emit requestError(result.data);
    }
}

const MethodDescriptor* GrpcClient::descriptor(GrpcQuery* query, const QString& fullMethodName)
{
    if (_pool && _factory) {
        const MethodDescriptor* methodDesc = _pool->FindMethodByName(fullMethodName.toStdString());

        if (methodDesc) {
            return methodDesc;
        }
    }

    QFileInfo fileInfo(query->filePath());

    if (!fileInfo.exists()) {
        return nullptr;
    }

    // parse proto
    compiler::DiskSourceTree sourceTree;
    sourceTree.MapPath("", fileInfo.absolutePath().toStdString());

    ProtoErrorCollector errorCollector;
    _importer = std::make_unique<compiler::Importer>(&sourceTree, &errorCollector);

    const FileDescriptor* fileDesc = _importer->Import(fileInfo.fileName().toStdString());

    if (!fileDesc) {
        return nullptr;
    }

    _pool = std::make_unique<DescriptorPool>(_importer->pool());
    _factory = std::make_unique<DynamicMessageFactory>(_importer->pool());

    return _pool->FindMethodByName(fullMethodName.toStdString());
}
