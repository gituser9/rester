#include "app.h"

using namespace std;

App::App(QObject* parent) : QObject{parent}
{
    // set path to config file
    QStringList cfgLocation = QStandardPaths::standardLocations(QStandardPaths::ConfigLocation);
    _configDirPath = cfgLocation.first() + "/rester";

    // setup props
    _isActiveSocketConnect = false;
    _query = nullptr;
    _grpcQuery = nullptr;
    _graphqlQuery = nullptr;
    _workspace = nullptr;
    _settings = nullptr;

    _routesFilterModel = std::make_shared<RoutesFilterModel>();

    // setup saver
    _saverThread = new QThread(this);
    _saverThread->start();

    _saver = std::make_shared<Saver>();
    _saver->moveToThread(_saverThread);

    // saver connects
    connect(_saver.get(), &Saver::saveError, this, &App::showError);
    connect(this, &App::wsChanged, _saver.get(), &Saver::saveWorkspace, Qt::QueuedConnection);
    connect(this, &App::settingsChanged, _saver.get(), &Saver::saveSettings, Qt::QueuedConnection);
}

App::~App()
{
    _saverThread->quit();
    _wsClientThread->quit();

    _saverThread->deleteLater();
    _wsClientThread->deleteLater();
}

void App::setup()
{
    setupRoutesModel();
    setupPinModel();
    setupWorkspaceModel();
    loadSettings();
}

Workspace* App::workspace() const
{
    return _workspace.get();
}

void App::setWorkspace(shared_ptr<Workspace> workspace)
{

    disconnect(_workspace.get(), &Workspace::pinsChanged, this, &App::queryUpdated);
    disconnect(_routesModel.get(), &RoutesModel::queryRemoved, _pinModel.get(), &PinModel::remove);
    disconnectQueries();

    _query = nullptr;
    _grpcQuery = nullptr;
    _graphqlQuery = nullptr;

    emit queryChanged(); // reset query views

    _workspace = workspace;
    _workspace->setLastUsageAt(QDateTime::currentMSecsSinceEpoch());
    _settings->setLastWorkspace(workspace->getFileName());

    emit wsReload(_workspace);
    emit wsChanged(_workspace);
    emit settingsChanged(_settings);

    _vars = _workspace->variables();

    emit workspaceChanged();

    auto currentVars = _vars[_workspace->env()].toList();
    setVars();

    connect(_workspace.get(), &Workspace::pinsChanged, this, &App::queryUpdated);
    connect(_routesModel.get(), &RoutesModel::queryRemoved, _pinModel.get(), &PinModel::remove);
}

void App::getSocketError(const QString& msg)
{
    emit socketError(msg);
}

void App::setupPinModel()
{
    if (_pinModel) {
        return;
    }

    _pinModel = std::make_shared<PinModel>(this);

    connect(this, &App::wsReload, _pinModel.get(), &PinModel::setWorkspace, Qt::QueuedConnection);
}

void App::setupHttpClient()
{
    if (_httpClient) {
        return;
    }

    disconnectClients();

    _httpClient = std::make_shared<HttpClient>();
    setVars();

    connect(_httpClient.get(), &HttpClient::finished, this, &App::setAnswer, Qt::QueuedConnection);
}

void App::setupGrpcClient()
{
    if (_grpcClient) {
        return;
    }

    disconnectClients();

    _grpcClient = std::make_shared<GrpcClient>();
    setVars();

    connect(_grpcClient.get(), &GrpcClient::requestFinished, this, &App::setGrpcAnswer, Qt::QueuedConnection);
}

void App::setupGraphqlClient()
{
    if (_graphqlClient) {
        return;
    }

    disconnectClients();

    _graphqlClient = std::make_shared<GraphqlClient>();
    setVars();

    connect(_graphqlClient.get(), &GraphqlClient::finished, this, &App::setGraphqlAnswer, Qt::QueuedConnection);
}

void App::setupWorkspaceModel()
{
    if (_workspaceModel) {
        return;
    }

    _workspaceModel = std::make_shared<WorkspaceModel>(this);

    // workspace model connects
    connect(_workspaceModel.get(), &WorkspaceModel::varsUpdate, this, &App::updateEnvVars);
    connect(_workspaceModel.get(), &WorkspaceModel::wsSave, _saver.get(), &Saver::saveWorkspace, Qt::QueuedConnection);
    connect(_workspaceModel.get(), &WorkspaceModel::wsSet, this, &App::setWorkspace);
    connect(_workspaceModel.get(), &WorkspaceModel::wsUpdate, this, &App::wsUpdate);
    connect(_workspaceModel.get(), &WorkspaceModel::error, this, &App::showError);
}

void App::setupRoutesModel()
{
    if (_routesModel) {
        return;
    }

    _routesModel = std::make_shared<RoutesModel>(this);
    _routesFilterModel->setSourceModel(_routesModel.get());

    // routes model connects
    connect(_routesModel.get(), &RoutesModel::treeChanged, _saver.get(), &Saver::saveWorkspace, Qt::QueuedConnection);
    connect(_routesModel.get(), &RoutesModel::setQuery, this, &App::setQuery);
    connect(_routesModel.get(), &RoutesModel::setGrpcQuery, this, &App::setGrpcQuery);
    connect(_routesModel.get(), &RoutesModel::setGraphqlQuery, this, &App::setGraphqlQuery);
    connect(_routesModel.get(), &RoutesModel::error, this, &App::showError);
    connect(_routesModel.get(), &RoutesModel::queryRemoved, this, &App::resetQuery, Qt::DirectConnection);

    connect(this, &App::wsReload, _routesModel.get(), &RoutesModel::loadTree, Qt::QueuedConnection);
}

void App::queryUpdated()
{
    emit wsChanged(_workspace);
}

void App::socketConnected()
{
    setIsActiveSocketConnect(true);
}

Settings* App::settings() const
{
    return _settings.get();
}

void App::setFromCurl(const QString& curl)
{
    auto parser = make_unique<CurlParser>();
    shared_ptr<Query> qry = parser->parse(curl);

    if (qry == nullptr) {
        emit showError("Parse cURL string error");

        return;
    }

    _query->setQueryType(qry->queryType());
    _query->setBodyType(qry->bodyType());
    _query->setHeaders(qry->headerList());
    _query->setUrl(qry->url());
    _query->setBody(qry->body());
    _query->setFormData(qry->formData());
    _query->parseParams();

    emit queryChanged();
    emit wsChanged(_workspace);
}

void App::setEnv(const QString& env)
{
    _workspace->setEnv(env);
    setVars();
}

void App::send()
{
    _httpClient->makeRequest(_query);
}

void App::callGrpc()
{
    _grpcClient->call(_grpcQuery);
}

void App::sendGraphql()
{
    _graphqlClient->makeRequest(_graphqlQuery);
}

void App::setQueryByUuid(const QString& uuid)
{
    auto node = _workspace->getQueryByUuid(uuid);

    if (node == nullptr) {
        return;
    }

    disconnectQueries();

    if (node->nodeType() == RstEnums::NodeType::QueryNode) {
        auto qry = static_cast<Query*>(node);
        _query = qry;
        _grpcQuery = nullptr;
        _graphqlQuery = nullptr;

        emit queryChanged();

        connect(_query, &Query::dataChanged, this, &App::queryUpdated);
        setupHttpClient();
    }

    if (node->nodeType() == RstEnums::NodeType::GrpcQueryNode) {
        auto qry = static_cast<GrpcQuery*>(node);
        _grpcQuery = qry;
        _query = nullptr;
        _graphqlQuery = nullptr;

        emit grpcQueryChanged();

        connect(_grpcQuery, &GrpcQuery::dataChanged, this, &App::queryUpdated);
        setupGrpcClient();
    }

    if (node->nodeType() == RstEnums::NodeType::GraphqlQueryNode) {
        auto qry = static_cast<GraphqlQuery*>(node);
        _graphqlQuery = qry;
        _query = nullptr;
        _grpcQuery = nullptr;

        emit graphqlQueryChanged();

        connect(_graphqlQuery, &GraphqlQuery::dataChanged, this, &App::queryUpdated);
        setupGraphqlClient();
    }
}

void App::connectToSocket()
{
    if (_isActiveSocketConnect) {
        return;
    }

    _wsClientThread = new QThread(this);
    _wsClientThread->start();

    _webSocketClient = std::make_shared<WebsocketClient>();
    _webSocketClient->moveToThread(_wsClientThread);

    // ws connects
    connect(_webSocketClient.get(), &WebsocketClient::received, this, &App::socketReceived);
    connect(_webSocketClient.get(), &WebsocketClient::connected, this, &App::socketConnected);
    connect(_webSocketClient.get(), &WebsocketClient::receivedError, this, &App::getSocketError);

    QString env = _workspace->env();
    QVariantList currentVars = _workspace->variables()[env].toList();

    _webSocketClient->open(_query->url(), currentVars);
    setIsActiveSocketConnect(true);
}

void App::disconnectSocket()
{
    if (_webSocketClient) {
        _webSocketClient->close();
        _webSocketClient->disconnect();
        _webSocketClient.reset();
    }

    if (_wsClientThread && _wsClientThread->isRunning()) {
        _wsClientThread->quit();
    }

    setIsActiveSocketConnect(false);
}

void App::sendToSocket(const QString& data)
{
    _webSocketClient->send(data);
}

void App::loadProto(const QString& filePath)
{
    QList<ProtoServiceInfo> protoInfo = _grpcClient->parseProtoFile(filePath);

    QStringList srv;
    QMap<QString, QStringList> rpc;

    for (auto&& info : protoInfo) {
        _grpcQuery->setPackage(info.packageName);
        srv << info.serviceName;
        rpc[info.serviceName] = {};

        for (auto&& method : info.methods) {
            rpc[info.serviceName].append(method.name);
        }
    }

    _grpcQuery->setAvailableSrv(srv);
    _grpcQuery->setAvailableRpc(rpc);
    _grpcQuery->setFilePath(filePath);

    if (srv.count() == 1) {
        _grpcQuery->setSrv(srv[0]);
    }

    emit grpcQueryChanged();
}

void App::reloadProto()
{
    if (!_grpcQuery) {
        emit showError("Request not exists");
        return;
    }

    if (!QFile::exists(_grpcQuery->filePath())) {
        emit showError("File does not exists");
        return;
    }

    loadProto(_grpcQuery->filePath());
}

void App::resetQuery(const QString& uuid)
{
    disconnectQueries();

    if (_query && _query->uuid() == uuid) {
        _query = nullptr;
        emit queryChanged();
    }

    if (_grpcQuery && _grpcQuery->uuid() == uuid) {
        _grpcQuery = nullptr;
        emit grpcQueryChanged();
    }

    if (_graphqlQuery && _graphqlQuery->uuid() == uuid) {
        _graphqlQuery = nullptr;
        emit graphqlQueryChanged();
    }
}

Query* App::query() const
{
    return _query;
}

GrpcQuery* App::grpcQuery() const
{
    return _grpcQuery;
}

void App::setQuery(Query* query)
{
    setupHttpClient();

    if (_query == query) {
        return;
    }

    disconnectQueries();

    _query = query;
    _grpcQuery = nullptr;
    _graphqlQuery = nullptr;

    emit queryChanged();

    if (_query) {
        connect(_query, &Query::dataChanged, this, &App::queryUpdated);
    }
}

void App::setGrpcQuery(GrpcQuery* query)
{
    setupGrpcClient();

    if (_grpcQuery == query) {
        return;
    }

    disconnectQueries();

    _grpcQuery = query;
    _query = nullptr;
    _graphqlQuery = nullptr;

    emit grpcQueryChanged();

    if (_grpcQuery) {
        connect(_grpcQuery, &GrpcQuery::dataChanged, this, &App::queryUpdated);
    }
}

void App::setGraphqlQuery(GraphqlQuery* query)
{
    setupGraphqlClient();

    if (_graphqlQuery == query) {
        return;
    }

    disconnectQueries();

    _graphqlQuery = query;
    _grpcQuery = nullptr;
    _query = nullptr;

    emit graphqlQueryChanged();

    if (_graphqlQuery) {
        connect(_graphqlQuery, &GraphqlQuery::dataChanged, this, &App::queryUpdated);
    }
}

void App::setAnswer(QSharedPointer<HttpAnswer> answer)
{
    _query->setAnswer(answer);
    _httpClient->setIsRequestWork(false);
}

void App::setGrpcAnswer(QSharedPointer<HttpAnswer> answer)
{
    _grpcQuery->setAnswer(answer);
    _grpcClient->setIsRequestWork(false);
}

void App::setGraphqlAnswer(QSharedPointer<HttpAnswer> answer)
{
    _graphqlQuery->setLastAnswer(answer);
    _graphqlClient->setIsRequestWork(false);
}

void App::wsUpdate(shared_ptr<Workspace> ws)
{
    _workspace->setName(ws->name());
    _settings->setLastWorkspace(ws->getFileName());

    emit wsChanged(_workspace);
    emit settingsChanged(_settings);
}

void App::loadSettings() noexcept
{
    _workspace = make_shared<Workspace>();

    // get settings
    _settings = make_shared<Settings>();
    _settings->loadFromFile(_configDirPath + "/settings.json");

    // from settings get last workspace
    QString lastWorkspace = _settings->lastWorkspace();

    if (lastWorkspace.isEmpty()) {
        _workspace->createDefault();
    }
    else {
        // read file
        QString filePath = _configDirPath + "/workspaces/" + lastWorkspace;
        QJsonObject json = Util::getJsonFromFile(filePath);

        if (json.isEmpty()) {
            _workspace->createDefault();
        }
        else {
            _workspace->fromJson(json);
        }

        _vars = _workspace->variables();
    }

    _workspace->setLastUsageAt(QDateTime::currentMSecsSinceEpoch());

    emit wsReload(_workspace);
    emit wsChanged(_workspace);

    connect(_workspace.get(), &Workspace::pinsChanged, this, &App::queryUpdated);
    connect(_routesModel.get(), &RoutesModel::queryRemoved, _pinModel.get(), &PinModel::remove);

    if (_settings->lastWorkspace().isEmpty()) {
        _settings->setLastWorkspace(_workspace->getFileName());
        emit settingsChanged(_settings);
    }
}

void App::disconnectQueries() noexcept
{
    if (_query != nullptr) {
        _query->disconnect();
    }

    if (_grpcQuery != nullptr) {
        _grpcQuery->disconnect();
    }

    if (_graphqlQuery != nullptr) {
        _graphqlQuery->disconnect();
    }
}

void App::disconnectClients() noexcept
{
    if (_httpClient) {
        _httpClient->disconnect();
        _httpClient.reset();
    }

    if (_grpcClient) {
        _grpcClient->disconnect();
        _grpcClient.reset();
    }

    if (_graphqlClient) {
        _graphqlClient->disconnect();
        _graphqlClient.reset();
    }
}

void App::setVars()
{
    QString currentEnv = _workspace->env();
    QVariantList currentVars = _workspace->variables()[currentEnv].toList();

    if (_httpClient) {
        _httpClient->setVars(currentVars);
    }

    if (_grpcClient) {
        _grpcClient->setVars(currentVars);
    }

    if (_graphqlClient) {
        _graphqlClient->setVars(currentVars);
    }
}

void App::updateEnvVars(const QVariantMap& vars)
{
    _vars = vars;
    _workspace->setVariables(vars);

    emit wsChanged(_workspace);
    emit workspaceChanged();
}

bool App::isActiveSocketConnect() const
{
    return _isActiveSocketConnect;
}

void App::setIsActiveSocketConnect(bool newIsActiveSocketConnect)
{
    if (_isActiveSocketConnect == newIsActiveSocketConnect) {
        return;
    }

    _isActiveSocketConnect = newIsActiveSocketConnect;

    emit isActiveSocketConnectChanged();
}

RoutesModel* App::routesModel() const
{
    return _routesModel.get();
}

RoutesFilterModel* App::routesFilterModel() const
{
    return _routesFilterModel.get();
}

PinModel* App::pinModel() const
{
    return _pinModel.get();
}

WorkspaceModel* App::workspaceModel() const
{
    return _workspaceModel.get();
}

HttpClient* App::httpClient() const
{
    return _httpClient.get();
}

GrpcClient* App::grpcClient() const
{
    return _grpcClient.get();
}

GraphqlQuery* App::graphqlQuery() const
{
    return _graphqlQuery;
}

GraphqlClient* App::graphqlClient() const
{
    return _graphqlClient.get();
}
