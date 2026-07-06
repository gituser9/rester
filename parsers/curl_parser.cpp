#include "curl_parser.h"

CurlParser::CurlParser() :
    _urlRegex("^https?:\\/\\/"),
    _varRegex(RstConstant::varRegexPattern)
{
}

std::shared_ptr<Query> CurlParser::parse(QString command)
{
    command = command.trimmed();
    auto query = std::make_shared<Query>();

    if (command.isEmpty()) {
        return query;
    }

    if (!command.startsWith("curl") || (command.length() > 4 && !command[4].isSpace())) {
        return query;
    }

    QStringList args = split(command.toStdString());
    ParseState state = ParseState::None;
    QString dataRaw = "";
    bool isDataRaw = false;

    for (const QString& arg : args) {
        if (_urlRegex.match(arg).hasMatch()) {
            query->setUrl(arg);
            continue;
        }

        if (arg == "-A" || arg == "--user-agent") {
            state = ParseState::UserAgent;
            continue;
        }

        if (arg == "-H" || arg == "--header") {
            state = ParseState::Header;
            continue;
        }

        if (arg == "-d" || arg == "--data" || arg == "--data-ascii") {
            state = ParseState::Data;
            continue;
        }

        if (arg == "--data-raw" || arg == "--data-binary") {
            state = ParseState::DataRaw;
            isDataRaw = true;
            continue;
        }

        if (arg == "-u" || arg == "--user") {
            state = ParseState::User;
            continue;
        }

        if (arg == "-I" || arg == "--head") {
            query->setQueryType(RstEnums::QueryType::HEAD);
            continue;
        }

        if (arg == "-X" || arg == "--request") {
            state = ParseState::Method;
            continue;
        }

        if (arg == "-b" || arg == "--cookie") {
            state = ParseState::Cookie;
            continue;
        }

        if (arg == "-F" || arg == "--form") {
            state = ParseState::Form;
            continue;
        }

        if (arg == "--compressed") {
            query->addHeader("Accept-Encoding", "gzip, deflate, br");
            continue;
        }

        // state
        if (state == ParseState::Header) {
            int separatorIndex = arg.indexOf(':');

            if (separatorIndex > 0) {
                QString name = arg.left(separatorIndex).trimmed().remove("'");
                QString value = arg.mid(separatorIndex + 1).trimmed().remove("'");
                query->addHeader(name, value);
            }

            state = ParseState::None;

            continue;
        }

        if (state == ParseState::UserAgent) {
            query->addHeader("User-Agent", arg);
            state = ParseState::None;

            continue;
        }

        if (state == ParseState::Data) {
            // check header, may be url-encided
            query->setBody(arg);
            state = ParseState::None;

            continue;
        }

        if (state == ParseState::DataRaw || state == ParseState::DataBinary) {
            dataRaw = arg;
            state = ParseState::None;

            continue;
        }

        if (state == ParseState::Form) {
            QStringList data = arg.split('=');

            if (data.size() != 2) {
                state = ParseState::None;

                continue;
            }

            if (data[1].startsWith("@")) {
                data[1] = data[1].replace("@", "file://");
            }

            query->addFormData(data.first(), data.last());
            state = ParseState::None;

            continue;
        }

        if (state == ParseState::User) {
            query->addHeader("Authorization", "Basic " + arg.toUtf8().toBase64());
            state = ParseState::None;

            continue;
        }

        if (state == ParseState::Method) {
            RstEnums::QueryType type = Util::getQueryType(arg);
            query->setQueryType(type);

            state = ParseState::None;

            continue;
        }

        if (state == ParseState::Cookie) {
            // query->addHeader("Set-Cookie", arg);
            query->addHeader("Cookie", arg);
            state = ParseState::None;
        }
    }

    // set body type
    QString contentType = Util::getHeaderValue("Content-Type", query->headerList()).toLower();

    if (!contentType.isEmpty()) {
        if (contentType.contains("application/json")) {
            query->setBodyType(RstEnums::BodyType::JSON);
        }

        if (contentType.contains("application/xml")) {
            query->setBodyType(RstEnums::BodyType::XML);
        }

        if (contentType.contains("application/x-www-form-urlencoded")) {
            query->setBodyType(RstEnums::BodyType::URL_ENCODED_FORM);
        }

        if (contentType.contains("multipart/form-data")) {
            query->setBodyType(RstEnums::BodyType::MULTIPART_FORM);
        }
    }
    else {
        if (!query->formData().isEmpty()) {
            query->setBodyType(RstEnums::BodyType::MULTIPART_FORM);
        }
        else if (!query->body().isEmpty()) {
            query->setBodyType(RstEnums::BodyType::JSON);
        }
    }

    if (isDataRaw) {
        if (query->bodyType() == RstEnums::BodyType::MULTIPART_FORM) {
            QList<QueryParam> formData = parseDataRaw(dataRaw);

            for (const QueryParam& item : formData) {
                query->addFormData(item.name(), item.value());
            }
        }
        else {
            query->setBody(dataRaw);
        }
    }

    // chrome not set method if data-raw exists and method POST
    bool isSetPost = (!query->formData().isEmpty() && query->queryType() == RstEnums::QueryType::GET) ||
                     (!query->body().isEmpty() && query->queryType() == RstEnums::QueryType::GET);

    if (isSetPost) {
        query->setQueryType(RstEnums::QueryType::POST);
    }

    return query;
}

QString CurlParser::generateCurl(Query* query) const noexcept // TODO: can static ?
{
    auto ws = Workspace::getByQuery(query);
    QVariantMap vars = ws->variables();
    QString currentEnv = vars.value("env", "").toString();
    QVariantList envVars = vars.value(currentEnv).toList();

    QString url = "  --url '" + CurlUtils::buildUrl(query->url(), envVars) + "' \\" + "\n";
    QString method = " --request " + Util::getQueryTypeString(query->queryType()) + " \\" + "\n";
    QString headers = CurlUtils::buildHeaders(query->headerList(), envVars);
    QString curlCommand = "curl" + method + url + headers + buildCurlBody(query);

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
        }
        else {
            std::string addition;

            if (!sq.empty()) {
                addition = sq;
            }
            else if (!dq.empty()) {
                addition = dq;
            }
            else if (!escape.empty()) {
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

QString CurlParser::buildCurlBody(Query* query) const noexcept
{
    RstEnums::BodyType bodyType = query->bodyType();

    if (bodyType == RstEnums::BodyType::JSON) {
        return "  --data '" + CurlUtils::escapeBody(query->body()) + "' \\\n";
    }
    else if (bodyType == RstEnums::BodyType::MULTIPART_FORM) {
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
    }
    else if (bodyType == RstEnums::BodyType::URL_ENCODED_FORM) {
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

        return "  --data '" + valuesString + "' \\" + "\n";
    }

    return "";
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
        QStringList itemsByLineBreaker = item.split(lineRegExp, Qt::SkipEmptyParts);

        if (itemsByLineBreaker.size() < 2) {
            continue;
        }

        QString name;
        QRegularExpressionMatch match = nameRegExp.match(item);

        if (match.hasMatch()) {
            name = match.captured(1);
        }
        else {
            continue;
        }

        QString value = itemsByLineBreaker[1]
                            .replace("rn", "")
                            .replace("\r\n", "");

        queryParams << QueryParam(name, value);
    }

    return queryParams;
}
