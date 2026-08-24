#include <memory>

#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include "app.h"
#include "highliters/html_syntax_highlighter.h"
#include "highliters/json_syntax_highlighter.h"
#include "highliters/graphql_syntax_highlighter.h"
#include "highliters/var_syntax_highlighter.h"
#include "highliters/url_highlighter.h"
#include "models/json_tree_model.h"
#include "models/xml_tree_model.h"
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

    App* core = new App(&app);
    core->setup();

    QQmlEngine::setObjectOwnership(core, QQmlEngine::CppOwnership);

    qmlRegisterSingletonInstance<App>("io.rester", 1, 0, "App", core);
    qmlRegisterSingletonInstance<Util>("io.rester", 1, 0, "Util", util.get());
    qmlRegisterType<JsonTreeModel>("io.rester", 1, 0, "JsonTreeModel");
    qmlRegisterType<XmlTreeModel>("io.rester", 1, 0, "XmlTreeModel");
    qmlRegisterType<HtmlSyntaxHighlighter>("io.rester", 1, 0, "HtmlSyntaxHighlighter");
    qmlRegisterType<JsonSyntaxHighlighter>("io.rester", 1, 0, "JsonSyntaxHighlighter");
    qmlRegisterType<GraphqlSyntaxHighlighter>("io.rester", 1, 0, "GraphqlSyntaxHighlighter");
    qmlRegisterType<VarSyntaxHighlighter>("io.rester", 1, 0, "VarSyntaxHighlighter");
    qmlRegisterType<UrlHighlighter>("io.rester", 1, 0, "UrlHighlighter");
    qmlRegisterType<SearchEngine>("io.rester", 1, 0, "SearchEngine");
    qmlRegisterType<HttpAnswer>("io.rester", 1, 0, "HttpAnswer");
    // qmlRegisterType<QueryParam>("io.rester", 1, 0, "QueryParam");
    qmlRegisterUncreatableType<RstEnums>("io.rester", 1, 0, "RstEnums", "RstEnums is an enum container");

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection //
    );

    QQuickStyle::setStyle("Imagine");

    engine.loadFromModule("io.rester", "Main");

    return app.exec();
}
