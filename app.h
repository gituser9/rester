#ifndef APP_H
#define APP_H

#include <memory>

#include <QDateTime>
#include <QStandardPaths>
#include <QThread>

#include "clients/http_client.h"
#include "clients/websocket_client.h"
#include "clients/grpc_client.h"
#include "clients/graphql_client.h"
#include "models/pin_model.h"
#include "models/routesmodel.h"
#include "models/routes_filter_proxy.h"
#include "models/worspace_model.h"
#include "parsers/curl_parser.h"

class App : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(Workspace* workspace READ workspace NOTIFY workspaceChanged FINAL)
    Q_PROPERTY(Query* query READ query NOTIFY queryChanged FINAL)
    Q_PROPERTY(GrpcQuery* grpcQuery READ grpcQuery NOTIFY grpcQueryChanged FINAL)
    Q_PROPERTY(GraphqlQuery* graphqlQuery READ graphqlQuery NOTIFY graphqlQueryChanged FINAL)
    Q_PROPERTY(Settings* settings READ settings NOTIFY settingsChanged FINAL)
    Q_PROPERTY(bool isActiveSocketConnect READ isActiveSocketConnect WRITE setIsActiveSocketConnect NOTIFY isActiveSocketConnectChanged FINAL)

    Q_PROPERTY(RoutesModel* routesModel READ routesModel CONSTANT)
    Q_PROPERTY(PinModel* pinModel READ pinModel CONSTANT)
    Q_PROPERTY(WorkspaceModel* workspaceModel READ workspaceModel CONSTANT)
    Q_PROPERTY(HttpClient* httpClient READ httpClient CONSTANT)
    Q_PROPERTY(GrpcClient* grpcClient READ grpcClient CONSTANT)
    Q_PROPERTY(GraphqlClient* graphqlClient READ graphqlClient CONSTANT)
    Q_PROPERTY(RoutesFilterModel* routesFilterModel READ routesFilterModel CONSTANT)

public:
    explicit App(QObject* parent = nullptr);
    ~App() override;

    void setup();

    // QML
    Q_INVOKABLE void setFromCurl(const QString& curl);
    Q_INVOKABLE void setEnv(const QString& env);
    Q_INVOKABLE void send();
    Q_INVOKABLE void callGrpc();
    Q_INVOKABLE void sendGraphql();
    Q_INVOKABLE void setQueryByUuid(const QString& uuid);
    Q_INVOKABLE void connectToSocket();
    Q_INVOKABLE void disconnectSocket();
    Q_INVOKABLE void sendToSocket(const QString& data);
    Q_INVOKABLE void loadProto(const QString& filePath);
    Q_INVOKABLE void reloadProto();
    Q_INVOKABLE void resetQuery();

    void setRoutesModel(const std::shared_ptr<RoutesModel>& newRoutesModel);
    void setWorkspaceModel(const std::shared_ptr<WorkspaceModel>& newWorkspaceModel);
    void setHttpClient(const std::shared_ptr<HttpClient>& newHttpClient);
    void setGrpcClient(const std::shared_ptr<GrpcClient> newHttpClient);
    void setGraphqlClient(const std::shared_ptr<GraphqlClient> newHttpClient);
    void setPinModel(const std::shared_ptr<PinModel>& newPinModel);

    // PROPERTIES
    Workspace* workspace() const;
    Query* query() const;
    GrpcQuery* grpcQuery() const;
    GraphqlQuery* graphqlQuery() const;
    Settings* settings() const;
    bool isActiveSocketConnect() const;
    void setIsActiveSocketConnect(bool newIsActiveSocketConnect);

    RoutesModel* routesModel() const;
    RoutesFilterModel* routesFilterModel() const;
    PinModel* pinModel() const;
    WorkspaceModel* workspaceModel() const;
    HttpClient* httpClient() const;
    GrpcClient* grpcClient() const;
    GraphqlClient* graphqlClient() const;

signals:
    void showError(const QString&);
    void wsChanged(std::shared_ptr<Workspace>);
    void wsReload(std::shared_ptr<Workspace>);
    void socketReceived(const QString&);
    void socketError(const QString&);

    // PROPERTIES
    void queryChanged();
    void grpcQueryChanged();
    void graphqlQueryChanged();
    void workspaceChanged();
    void settingsChanged(std::shared_ptr<Settings>);
    void isActiveSocketConnectChanged();

public slots:
    void setWorkspace(std::shared_ptr<Workspace> workspace);
    void getSocketError(const QString& msg);

    // test grpc slot
    // void grpcRequestFinished(const QString& jsonResponse);
    // void requestError(const QString& errorMessage);

private:
    std::shared_ptr<RoutesModel> _routesModel;
    std::shared_ptr<RoutesFilterModel> _routesFilterModel;
    std::shared_ptr<WorkspaceModel> _workspaceModel;
    std::shared_ptr<PinModel> _pinModel;

    std::shared_ptr<HttpClient> _httpClient;
    std::shared_ptr<GrpcClient> _grpcClient;
    std::shared_ptr<GraphqlClient> _graphqlClient;
    std::shared_ptr<WebsocketClient> _webSocketClient;
    std::shared_ptr<Saver> _saver;

    QThread* _saverThread = nullptr;
    QThread* _wsClientThread = nullptr;
    QString _configDirPath;
    QString _env;
    QVariantMap _vars;

    // PROPERTIES
    Query* _query = nullptr;
    GrpcQuery* _grpcQuery = nullptr;
    GraphqlQuery* _graphqlQuery = nullptr;
    std::shared_ptr<Workspace> _workspace;
    std::shared_ptr<Settings> _settings;
    bool _isActiveSocketConnect;

    void loadSettings() noexcept;
    void disconnectQueries() noexcept;

private slots:
    // workspace model
    void updateEnvVars(const QVariantMap& vars);
    void wsUpdate(std::shared_ptr<Workspace> ws);

    void setQuery(Query* query);
    void setGrpcQuery(GrpcQuery* query);
    void setGraphqlQuery(GraphqlQuery* query);
    void setAnswer(QSharedPointer<HttpAnswer> answer);
    void setGrpcAnswer(QSharedPointer<HttpAnswer> answer);
    void setGraphqlAnswer(QSharedPointer<HttpAnswer> answer);
    void queryUpdated();
    void socketConnected();
};

#endif // APP_H
