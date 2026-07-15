#ifndef UTIL_H
#define UTIL_H

#include <optional>

#include <QFile>
#include <QJsonDocument>
#include <QObject>
#include <QRegularExpression>
#include <QStack>
#include <QTextDocument>
#include <QUuid>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>
#include <QStringList>

#include "app_data/constant.h"
#include "app_data/folder.h"
#include "app_data/query_param.h"

class Util : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    Util(QObject* parent = nullptr);

    Q_INVOKABLE static RstEnums::QueryType getQueryType(QString typeString);
    Q_INVOKABLE static RstEnums::BodyType getBodyType(QString typeString);
    Q_INVOKABLE static QString getBodyTypeString(RstEnums::BodyType type);
    Q_INVOKABLE static QString getHumanBodyTypeString(RstEnums::BodyType type);
    static QString beautify(QString body, QVariantMap headers);
    static QString uuid() noexcept;
    static QString getHeaderValue(const QString& name, const QList<QueryParam>& headers) noexcept;
    static QString getHeaderValue(const QString& name, const QVariantMap& headers) noexcept;
    static QString fillVars(const QString& str, const QVariantList& vars) noexcept;
    static QString fillVars(const QString& str, const QVariantList& vars, QRegularExpression varRegex) noexcept;
    static QJsonObject getJsonFromFile(const QString& path) noexcept;
    static void writeJsonToFile(const QString& path, const QJsonObject& json) noexcept;
    static void writeToFile(const QString& path, const QString& data) noexcept;

    Q_INVOKABLE static QString beautify(QString body, RstEnums::BodyType bodyType);
    Q_INVOKABLE static QString getQueryTypeString(RstEnums::QueryType type);
    Q_INVOKABLE static double round2digits(double num) noexcept;
    Q_INVOKABLE static QVariantMap getAnswerSize(qint64 bytesCount) noexcept;
    Q_INVOKABLE static QString getAnswerSizeString(qint64 bytesCount) noexcept;
    Q_INVOKABLE static QStringList filterBigBody(const QString& body, const QString& searchString) noexcept;

private:
    static std::optional<QJsonValue> findSubstring(const QJsonValue& value, const QString& substring, const QString& parentKey = QString());
};

#endif // UTIL_H
