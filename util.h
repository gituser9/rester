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

class Util : public QObject {
    Q_OBJECT

public:
    explicit Util(QObject* parent = nullptr);

    static QueryType getQueryType(QString typeString);
    static BodyType getBodyType(QString typeString);
    static QString getBodyTypeString(BodyType type);
    static QString beautify(QString body, BodyType bodyType);
    static QString beautify(QString body, QVariantMap headers);
    static QString uuid() noexcept;
    static QString getHeaderValue(const QString& name, const QList<QueryParam>& headers) noexcept;
    static QString getHeaderValue(const QString& name, const QVariantMap& headers) noexcept;
    static QJsonObject getJsonFromFile(const QString& path) noexcept;
    static void writeJsonToFile(const QString& path, const QJsonObject& json) noexcept;

    Q_INVOKABLE static QString getQueryTypeString(QueryType type);
    Q_INVOKABLE static double round2digits(double num) noexcept;
    Q_INVOKABLE static QVariantMap getAnswerSize(qint64 bytesCount) noexcept;
    Q_INVOKABLE static QStringList filterBigBody(const QString& body, const QString& searchString) noexcept;

private:
    static std::optional<QJsonValue> findSubstring(const QJsonValue& value, const QString& substring, const QString& parentKey = QString());
};

#endif // UTIL_H
