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
#include "../util.h"

class CurlParser {
public:
    explicit CurlParser();

    std::shared_ptr<Query> parse(QString command);
    QString generateCurl(Query* query) const noexcept;

private:
    std::unique_ptr<QRegularExpression> _urlRegex;

    QStringList split(std::string line = "") const noexcept;
    QString generateCurlHeaders(Query* query) const noexcept;
    QString generateCurlBody(Query* query) const noexcept;
    QString generateCurlUrl(Query* query) const noexcept;
    QString excapeCurlBody(Query* query) const noexcept;
    QList<QueryParam> parseDataRaw(const QString& dataRaw) const noexcept;
};

#endif // CURLPARSER_H
