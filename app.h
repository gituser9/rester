#ifndef APP_H
#define APP_H

#include <memory>

#include <QDateTime>
#include <QStandardPaths>
#include <QThread>

#include "clients/http_client.h"
#include "clients/websocket_client.h"
#include "models/pin_model.h"
#include "models/routesmodel.h"
#include "models/worspace_model.h"
#include "parsers/curl_parser.h"

class App : public QObject {
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT

    Q_PROPERTY(Workspace* workspace READ workspace NOTIFY workspaceChanged FINAL)
    Q_PROPERTY(Query* query READ query NOTIFY queryChanged FINAL)
    Q_PROPERTY(Settings* settings READ settings NOTIFY settingsChanged FINAL)
    Q_PROPERTY(bool isActiveSocketConnect READ isActiveSocketConnect WRITE setIsActiveSocketConnect NOTIFY isActiveSocketConnectChanged FINAL)

public:
    explicit App(QObject* parent = nullptr);
    virtual ~App();

    void setup();

    // QML
    Q_INVOKABLE void setFromCurl(const QString& curl);
    Q_INVOKABLE void setEnv(const QString& env);
    Q_INVOKABLE void send();
    Q_INVOKABLE void setQueryByUuid(const QString& uuid);
    Q_INVOKABLE void connectToSocket();
    Q_INVOKABLE void disconnectSocket();
    Q_INVOKABLE void sendToSocket(const QString& data);

    void setRoutesModel(const std::shared_ptr<RoutesModel>& newRoutesModel);
    void setWorkspaceModel(const std::shared_ptr<WorkspaceModel>& newWorkspaceModel);
    void setHttpClient(const std::shared_ptr<HttpClient>& newHttpClient);
    void setPinModel(const std::shared_ptr<PinModel>& newPinModel);

    // PROPERTIES
    Workspace* workspace() const;
    Query* query() const;
    Settings* settings() const;
    bool isActiveSocketConnect() const;
    void setIsActiveSocketConnect(bool newIsActiveSocketConnect);

signals:
    void showError(const QString&);
    void wsChanged(std::shared_ptr<Workspace>);
    void wsReload(std::shared_ptr<Workspace>);
    void socketReceived(const QString&);
    void socketError(const QString&);

    // PROPERTIES
    void queryChanged();
    void workspaceChanged();
    void settingsChanged(std::shared_ptr<Settings>);
    void isActiveSocketConnectChanged();

public slots:
    void setWorkspace(std::shared_ptr<Workspace> workspace);
    void getSocketError(const QString& msg);

private:
    std::shared_ptr<RoutesModel> _routesModel;
    std::shared_ptr<WorkspaceModel> _workspaceModel;
    std::shared_ptr<PinModel> _pinModel;

    std::shared_ptr<HttpClient> _httpClient;
    std::shared_ptr<WebsocketClient> _webSocketClient;
    std::shared_ptr<Saver> _saver;

    QThread* _saverThread = nullptr;
    QThread* _httpClientThread = nullptr;
    QThread* _wsClientThread = nullptr;
    QString _configDirPath;
    QString _env;
    QVariantMap _vars;

    // PROPERTIES
    Query* _query = nullptr;
    std::shared_ptr<Workspace> _workspace;
    std::shared_ptr<Settings> _settings;
    bool _isActiveSocketConnect;

    void loadSettings() noexcept;
    void modelConnections() noexcept;


private slots:
    // workspace model
    void updateEnvVars(const QVariantMap& vars);
    void wsUpdate(std::shared_ptr<Workspace> ws);

    void setQuery(Query* query);
    void setAnswer(QSharedPointer<HttpAnswer> answer);
    void queryUpdated();
    void socketConnected();
};

#endif // APP_H
