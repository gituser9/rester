#include "curl_parser.h"

CurlParser::CurlParser()
{
    _urlRegex = std::make_unique<QRegularExpression>();
    _urlRegex->setPattern("^https?:\\/\\/");
}

std::shared_ptr<Query> CurlParser::parse(QString command)
{
    command = command.trimmed();
    auto query = std::make_shared<Query>();

    if (command.isEmpty()) {
        return query;
    }

    if (!command.startsWith("curl")) {
        return query;
    }

    QStringList args = split(command.toStdString());
    QString state = "";
    QString dataRaw = "";
    bool isDataRaw = false;

    for (const QString& arg : args) {
        if (_urlRegex->match(arg).hasMatch()) {
            query->setUrl(arg);
            continue;
        }

        if (arg == "-A" || arg == "--user-agent") {
            state = "user-agent";
            continue;
        }

        if (arg == "-H" || arg == "--header") {
            state = "header";
            continue;
        }

        if (arg == "-d" || arg == "--data" || arg == "--data-ascii") {
            state = "data";
            continue;
        }

        if (arg == "--data-raw" || arg == "--data-binary") {
            state = "data-raw";
            isDataRaw = true;
            continue;
        }

        if (arg == "-u" || arg == "--user") {
            state = "user";
            continue;
        }

        if (arg == "-I" || arg == "--head") {
            query->setQueryType(QueryType::HEAD);
            continue;
        }

        if (arg == "-X" || arg == "--request") {
            state = "method";
            continue;
        }

        if (arg == "-b" || arg == "--cookie") {
            state = "cookie";
            continue;
        }

        if (arg == "-F" || arg == "--form") {
            state = "form";
            continue;
        }

        if (arg == "--compressed") {
            query->addHeader("Accept-Encoding", "gzip, deflate, br");
            continue;
        }

        // state
        if (state == "header") {
            QStringList field = arg.split(":");
            query->addHeader(field.first().trimmed().remove("'"), field.last().trimmed().remove("'"));

            state.clear();

            continue;
        }

        if (state == "user-agent") {
            query->addHeader("User-Agent", arg);
            state.clear();

            continue;
        }

        if (state == "data") {
            // check header, may be url-encided
            query->setBody(arg);
            state.clear();

            continue;
        }

        if (state == "data-raw" || state == "data-binary") {
            dataRaw = arg;
            state.clear();

            continue;
        }

        if (state == "form") {
            QStringList data = arg.split('=');

            if (data.size() != 2) {
                state.clear();

                continue;
            }

            if (data[1].startsWith("@")) {
                data[1] = data[1].replace("@", "file://");
            }

            query->addFormData(data.first(), data.last());
            state.clear();

            continue;
        }

        if (state == "user") {
            query->addHeader("Authorization", "Basic " + arg.toUtf8().toBase64());
            state.clear();

            continue;
        }

        if (state == "method") {
            QueryType type = Util::getQueryType(arg);
            query->setQueryType(type);

            state.clear();

            continue;
        }

        if (state == "cookie") {
            query->addHeader("Set-Cookie", arg);
            state.clear();
        }
    }

    // set body type
    QString contentType = Util::getHeaderValue("Content-Type", query->headerList()).toLower();

    if (!contentType.isEmpty()) {
        if (contentType.contains("application/json")) {
            query->setBodyType(BodyType::JSON);
        }

        if (contentType.contains("application/xml")) {
            query->setBodyType(BodyType::XML);
        }

        if (contentType.contains("application/x-www-form-urlencoded")) {
            query->setBodyType(BodyType::URL_ENCODED_FORM);
        }

        if (contentType.contains("multipart/form-data")) {
            query->setBodyType(BodyType::MULTIPART_FORM);
        }
    } else {
        if (!query->formData().isEmpty()) {
            query->setBodyType(BodyType::MULTIPART_FORM);
        } else if (!query->body().isEmpty()) {
            query->setBodyType(BodyType::JSON);
        }
    }

    if (isDataRaw) {
        if (query->bodyType() == BodyType::MULTIPART_FORM) {
            auto formData = parseDataRaw(dataRaw);

            for (const QueryParam& item : formData) {
                query->addFormData(item.name(), item.value());
            }

        } else {
            query->setBody(dataRaw);
        }
    }

    // chrome not set method if data-raw exists and method POST
    bool isSetPost = (!query->formData().isEmpty() && query->queryType() == QueryType::GET)
        || (!query->body().isEmpty() && query->queryType() == QueryType::GET);

    if (isSetPost) {
        query->setQueryType(QueryType::POST);
    }

    return query;
}

QString CurlParser::generateCurl(Query* query) const noexcept
{
    QString url = "  --url '" + generateCurlUrl(query) + "' \\" + "\n";
    QString method = " --request " + Util::getQueryTypeString(query->queryType()) + " \\" + "\n";
    QString curlCommand = "curl" + method + url + generateCurlHeaders(query) + generateCurlBody(query);

    qsizetype pos = curlCommand.lastIndexOf("\\");

    if (pos != -1) {
        curlCommand = curlCommand.left(pos);
    }

    return curlCommand;
}

QStringList CurlParser::split(std::string line) const noexcept
{
    QStringList words;
    std::string field = "";
    std::regex pattern("\\s*(?:([^\\s\\\\\\'\\\"]+)|'((?:[^\\'\\\\]|\\\\.)*)'|\"((?:[^\\\"\\\\]|\\\\.)*)\"|(\\\\.?)|(\\S))(\\s|$)?");
    std::sregex_iterator matchIterator(line.begin(), line.end(), pattern);
    std::sregex_iterator endIterator;

    while (matchIterator != endIterator) {
        std::smatch match = *matchIterator;
        const std::string word = match[1].str();
        const std::string sq = match[2].str();
        const std::string dq = match[3].str();
        const std::string escape = match[4].str();
        const std::string garbage = match[5].str();
        const std::string separator = match[6].str();

        if (!garbage.empty()) {
            return words;
        }

        if (!word.empty()) {
            field += word;
        } else {
            std::string addition;

            if (!sq.empty()) {
                addition = sq;
            } else if (!dq.empty()) {
                addition = dq;
            } else if (!escape.empty()) {
                addition = escape;
            }

            if (!addition.empty()) {
                field += std::regex_replace(addition, std::regex("\\\\(?=.)"), "");
            }
        }

        if (!separator.empty()) {
            words.append(QString::fromStdString(field));
            field = "";
        }

        ++matchIterator;
    }

    if (!field.empty()) {
        words.append(QString::fromStdString(field));
    }

    return words;
}

QString CurlParser::generateCurlHeaders(Query* query) const noexcept
{
    QString headerString;

    for (auto header : query->headerList()) {
        if (!header.isEnabled()) {
            continue;
        }

        headerString += "  --header '" + header.name() + ": " + header.value() + "' \\" + "\n";
    }

    return headerString;
}

QString CurlParser::generateCurlBody(Query* query) const noexcept
{
    BodyType bodyType = query->bodyType();

    if (bodyType == BodyType::JSON) {
        return "  --data '" + excapeCurlBody(query) + "' \\" + "'\n";
    } else if (bodyType == BodyType::MULTIPART_FORM) {
        QVariantList formData = query->formData();
        QString valuesString;

        for (const QVariant& item : formData) {
            QueryParam data(item);

            QString name = data.name();
            QString value = data.value();

            if (value.startsWith("file://")) {
                value = "@" + value.replace("file://", "");
            }

            valuesString += "  --form '" + name + "=" + value + "' \\" + "\n";
        }
        return valuesString;
    } else if (bodyType == BodyType::URL_ENCODED_FORM) {
        QString valuesString;
        QVariantList formData = query->formData();

        for (const QVariant& item : formData) {
            QueryParam data(item);

            QString name = data.name();
            QString value = data.value();

            valuesString += name + "=" + value + "&";
        }
        qsizetype pos = valuesString.lastIndexOf("&");

        if (pos != -1) {
            valuesString = valuesString.left(pos);
        }

        return "  --data '" + valuesString + "' \\" + "'\n";
    }

    return "";
}

QString CurlParser::generateCurlUrl(Query* query) const noexcept
{
    auto ws = Workspace::getByQuery(query);
    QVariantMap vars = ws->variables();
    QString currentEnv = vars.value("env", "").toString();
    QVariantList envVars = vars.value(currentEnv).toList();

    QString urlString = query->url();
    auto varRegex = QRegularExpression("{{\\s*(.*?)\\s*}}");

    if (!envVars.isEmpty()) {
        QRegularExpressionMatchIterator iter = varRegex.globalMatch(urlString);

        while (iter.hasNext()) {
            QRegularExpressionMatch match = iter.next();
            QString variable = match.captured(1).trimmed();

            for (const QVariant& var : envVars) {
                QVariantMap varMap = var.toMap();

                if (varMap["name"] == variable) {
                    urlString = urlString.replace("{{" + variable + "}}", varMap["value"].toString());
                }
            }
        }
    }

    QUrl url = urlString;
    QUrlQuery urlParams;

    for (const QueryParam& param : query->paramList()) {
        if (!param.isEnabled()) {
            continue;
        }

        urlParams.addQueryItem(param.name(), param.value());
    }

    url.setQuery(urlParams.toString(QUrl::FullyEncoded));

    return url.toString();
}

QString CurlParser::excapeCurlBody(Query* query) const noexcept
{
    QString escapedBody = query->body();
    escapedBody.replace("'", "'\\''");

    return escapedBody;
}

QList<QueryParam> CurlParser::parseDataRaw(const QString& dataRaw) const noexcept
{
    if (dataRaw.isEmpty()) {
        return {};
    }

    QList<QueryParam> queryParams;
    QRegularExpression nameRegExp("name=\"([^\"]*)\"");
    QStringList items = dataRaw.split(QRegularExpression("\n|\r\n|rn|\r"), Qt::SkipEmptyParts);

    if (items.isEmpty()) {
        return {};
    }

    QString del1 = items[0];
    QString del2 = items[0].replace("$", "");
    QStringList itemsByDelimeter = dataRaw.split(QRegularExpression(del1 + "|" + del2), Qt::SkipEmptyParts);
    QRegularExpression lineRegExp("rnrn|\r\n\r\n");

    for (const QString& item : itemsByDelimeter) {
        // QStringList itemsByLineBreaker = item.split("rnrn", Qt::SkipEmptyParts);
        QStringList itemsByLineBreaker = item.split(lineRegExp, Qt::SkipEmptyParts);

        if (itemsByLineBreaker.size() < 2) {
            continue;
        }

        QString name;
        QRegularExpressionMatch match = nameRegExp.match(item);

        if (match.hasMatch()) {
            name = match.captured(1);
        } else {
            continue;
        }

        QString value = itemsByLineBreaker[1]
                            .replace("rn", "")
                            .replace("\r\n", "");

        queryParams << QueryParam(name, value);
    }

    return queryParams;
}
