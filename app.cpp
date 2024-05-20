#include "app.h"

using namespace std;

App::App(QObject* parent)
    : QObject { parent }
{
    // set path to config file
    QStringList cfgLocation = QStandardPaths::standardLocations(QStandardPaths::ConfigLocation);
    _configDirPath = cfgLocation.first() + "/rester";

    // setup props
    _isActiveSocketConnect = false;
    _query = nullptr;
    _workspace = nullptr;
    _settings = nullptr;

    // setup saver
    _saverThread = new QThread();
    _saverThread->start();

    _saver = make_shared<Saver>();
    _saver->moveToThread(_saverThread);

    // setup ws
    _wsClientThread = new QThread();
    _wsClientThread->start();

    _webSocketClient = make_shared<WebsocketClient>();
    _webSocketClient->moveToThread(_wsClientThread);

    // saver connects
    connect(_saver.get(), &Saver::saveError, this, &App::showError);
    connect(this, &App::wsChanged, _saver.get(), &Saver::saveWorkspace, Qt::QueuedConnection);
    connect(this, &App::settingsChanged, _saver.get(), &Saver::saveSettings, Qt::QueuedConnection);

    // ws connects
    connect(_webSocketClient.get(), &WebsocketClient::received, this, &App::socketReceived);
    connect(_webSocketClient.get(), &WebsocketClient::connected, this, &App::socketConnected);
    connect(_webSocketClient.get(), &WebsocketClient::receivedError, this, &App::getSocketError);
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
    modelConnections();
    loadSettings();
}

Workspace* App::workspace() const
{
    return _workspace.get();
}

void App::setWorkspace(shared_ptr<Workspace> workspace)
{
    _workspace = workspace;
    _workspace->setLastUsageAt(QDateTime::currentMSecsSinceEpoch());

    _query = nullptr;
    _settings->setLastWorkspace(workspace->getFileName());

    emit wsReload(_workspace);
    emit queryChanged();
    emit wsChanged(_workspace);
    emit settingsChanged(_settings);

    _vars = _workspace->variables();

    emit workspaceChanged();

    auto currentVars = _vars[_workspace->env()].toList();
    _httpClient->setVars(currentVars);

    connect(_workspace.get(), &Workspace::pinsChanged, this, &App::queryUpdated); // todo: slot
    connect(_routesModel.get(), &RoutesModel::queryRemoved, _pinModel.get(), &PinModel::remove);
}

void App::getSocketError(const QString &msg)
{
    emit socketError(msg);
}

void App::setPinModel(const std::shared_ptr<PinModel>& newPinModel)
{
    _pinModel = newPinModel;

    connect(this, &App::wsReload, _pinModel.get(), &PinModel::setWorkspace, Qt::QueuedConnection);
}

void App::setHttpClient(const std::shared_ptr<HttpClient>& newHttpClient)
{
    _httpClient = newHttpClient;

    // http client model connects
    connect(_httpClient.get(), &HttpClient::finished, this, &App::setAnswer, Qt::QueuedConnection);
}

void App::setWorkspaceModel(const std::shared_ptr<WorkspaceModel>& newWorkspaceModel)
{
    _workspaceModel = newWorkspaceModel;

    // workspace model connects
    connect(_workspaceModel.get(), &WorkspaceModel::varsUpdate, this, &App::updateEnvVars);
    connect(_workspaceModel.get(), &WorkspaceModel::wsSave, _saver.get(), &Saver::saveWorkspace, Qt::QueuedConnection);
    connect(_workspaceModel.get(), &WorkspaceModel::wsSet, this, &App::setWorkspace);
    connect(_workspaceModel.get(), &WorkspaceModel::wsUpdate, this, &App::wsUpdate);
    connect(_workspaceModel.get(), &WorkspaceModel::error, this, &App::showError);
}

void App::setRoutesModel(const std::shared_ptr<RoutesModel>& newRoutesModel)
{
    _routesModel = newRoutesModel;

    // routes model connects
    connect(_routesModel.get(), &RoutesModel::treeChanged, _saver.get(), &Saver::saveWorkspace, Qt::QueuedConnection);
    connect(_routesModel.get(), &RoutesModel::setQuery, this, &App::setQuery);
    connect(_routesModel.get(), &RoutesModel::error, this, &App::showError);

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
    _query->setHeaders(qry->headers());
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

    auto currentVars = _workspace->variables()[env].toList();
    _httpClient->setVars(currentVars);
}

void App::send()
{
    _httpClient->makeRequest(_query);
}

void App::setQueryByUuid(const QString& uuid)
{
    auto node = _workspace->getQueryByUuid(uuid);

    if (node == nullptr) {
        return;
    }

    auto qry = static_cast<Query*>(node);
    _query = qry;

    emit queryChanged();

    connect(_query, &Query::dataChanged, this, &App::queryUpdated);
}

void App::connectToSocket()
{
    QString env = _workspace->env();
    QVariantList currentVars = _workspace->variables()[env].toList();

    _webSocketClient->open(_query->url(), currentVars);
}

void App::disconnectSocket()
{
    _webSocketClient->close();
    setIsActiveSocketConnect(false);
}

void App::sendToSocket(const QString &data)
{
    _webSocketClient->send(data);
}

Query* App::query() const
{
    return _query;
}

void App::setQuery(Query* query)
{
    if (_query == query) {
        return;
    }

    _query = query;

    emit queryChanged();

    connect(_query, &Query::dataChanged, this, &App::queryUpdated);
}

void App::setAnswer(QSharedPointer<HttpAnswer> answer)
{
    _query->setAnswer(answer);
    _httpClient->setIsRequestWork(false);
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
    } else {
        // read file
        QString filePath = _configDirPath + "/workspaces/" + lastWorkspace;
        QJsonObject json = Util::getJsonFromFile(filePath);

        if (json.isEmpty()) {
            _workspace->createDefault();
        } else {
            _workspace->fromJson(json);
        }

        _vars = _workspace->variables();

        auto currentVars = _vars[_workspace->env()].toList();
        _httpClient->setVars(currentVars);
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

void App::modelConnections() noexcept
{
}

void App::updateEnvVars(const QVariantMap& vars)
{
    _vars = vars;
    _workspace->setVariables(vars);

    auto currentVars = vars[_workspace->env()].toList();
    _httpClient->setVars(currentVars);
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
