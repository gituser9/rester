#include <memory>

#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "app.h"
#include "clients/http_client.h"
#include "clients/grpc_client.h"
#include "highliters/html_syntax_highlighter.h"
#include "highliters/json_syntax_highlighter.h"
#include "highliters/var_syntax_highlighter.h"
#include "models/pin_model.h"
#include "models/routesmodel.h"
#include "models/worspace_model.h"
#include "search_engine.h"
#include "util.h"

int main(int argc, char* argv[])
{
    QGuiApplication app(argc, argv);

    // app.setWindowIcon()
#ifdef QT_DEBUG
    // QLoggingCategory::setFilterRules(QStringLiteral("default.debug=true"));
#endif

    auto util = std::make_shared<Util>();
    auto routesModel = std::make_shared<RoutesModel>();
    auto workspaceModel = std::make_shared<WorkspaceModel>();
    auto pinModel = std::make_shared<PinModel>();
    auto httpClient = std::make_shared<HttpClient>();
    auto grpcClient = std::make_shared<GrpcClient>();

    App* core = new App(&app);
    core->setRoutesModel(routesModel);
    core->setWorkspaceModel(workspaceModel);
    core->setPinModel(pinModel);
    core->setHttpClient(httpClient);
    core->setGrpcClient(grpcClient);
    core->setup();

    qmlRegisterSingletonInstance<App>("core.app", 1, 0, "App", core);
    qmlRegisterSingletonInstance<RoutesModel>("RoutesModel", 1, 0, "RoutesModel", routesModel.get());
    qmlRegisterSingletonInstance<HttpClient>("HttpClient", 1, 0, "HttpClient", httpClient.get());
    qmlRegisterSingletonInstance<GrpcClient>("GrpcClient", 1, 0, "GrpcClient", grpcClient.get());
    qmlRegisterSingletonInstance<Util>("Util", 1, 0, "Util", util.get());
    qmlRegisterSingletonInstance<WorkspaceModel>("WorkspaceModel", 1, 0, "WorkspaceModel", workspaceModel.get());
    qmlRegisterSingletonInstance<PinModel>("PinModel", 1, 0, "PinModel", pinModel.get());
    qmlRegisterType<HtmlSyntaxHighlighter>("HtmlSyntaxHighlighter", 1, 0, "HtmlSyntaxHighlighter");
    qmlRegisterType<JsonSyntaxHighlighter>("JsonSyntaxHighlighter", 1, 0, "JsonSyntaxHighlighter");
    qmlRegisterType<VarSyntaxHighlighter>("VarSyntaxHighlighter", 1, 0, "VarSyntaxHighlighter");
    qmlRegisterType<SearchEngine>("SearchEngine", 1, 0, "SearchEngine");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection //
    );

    QQuickStyle::setStyle("Imagine");
    // QQuickStyle::setStyle("FluentWinUI3");
    // QQuickStyle::setStyle("Material");

    engine.loadFromModule("io.rester", "Main");

    return app.exec();
}
