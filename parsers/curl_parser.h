#ifndef CURLPARSER_H
#define CURLPARSER_H

#include <functional>
#include <memory>
#include <regex>
#include <vector>

#include <QMap>
#include <QObject>
#include <QRegularExpression>
#include <QString>
#include <QStringList>
#include <QUrl>
#include <QUrlQuery>
#include <QVariantMap>

#include "../app_data/workspace.h"
#include "curl_utils.h"

class CurlParser
{
public:
    explicit CurlParser();

    std::shared_ptr<Query> parse(QString command);
    QString generateCurl(Query* query) const noexcept;

private:
    QRegularExpression _urlRegex;
    QRegularExpression _varRegex;

    enum class ParseState {
        None,
        Header,
        UserAgent,
        Data,
        DataRaw,
        DataBinary,
        Form,
        User,
        Method,
        Cookie,
    };

    QStringList split(std::string line = "") const noexcept;
    void extracted(Query*& query, QVariantList& envVars, QString& headerString) const;
    QString buildCurlBody(Query* query) const noexcept;
    QString excapeCurlBody(Query* query) const noexcept;
    QList<QueryParam> parseDataRaw(const QString& dataRaw) const noexcept;
};

#endif // CURLPARSER_H
