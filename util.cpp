#include "util.h"

using namespace std;

Util::Util(QObject* parent)
    : QObject { parent }
{
}

QueryType Util::getQueryType(QString typeString)
{
    if (typeString == "GET") {
        return QueryType::GET;
    }

    if (typeString == "POST") {
        return QueryType::POST;
    }

    if (typeString == "PUT") {
        return QueryType::PUT;
    }

    if (typeString == "PATCH") {
        return QueryType::PATCH;
    }

    if (typeString == "DELETE") {
        return QueryType::DELETE;
    }

    if (typeString == "WS") {
        return QueryType::WS;
    }

    return QueryType::GET;
}

BodyType Util::getBodyType(QString typeString)
{
    if (typeString == "JSON") {
        return BodyType::JSON;
    }

    if (typeString == "XML") {
        return BodyType::XML;
    }

    if (typeString == "MULTIPART_FORM") {
        return BodyType::MULTIPART_FORM;
    }

    if (typeString == "URL_ENCODED_FORM") {
        return BodyType::URL_ENCODED_FORM;
    }

    return BodyType::NONE;
}

QString Util::getQueryTypeString(QueryType type)
{
    switch (type) {
    case QueryType::GET:
        return "GET";
    case QueryType::POST:
        return "POST";
    case QueryType::PATCH:
        return "PATCH";
    case QueryType::PUT:
        return "PUT";
    case QueryType::DELETE:
        return "DELETE";
    case QueryType::WS:
        return "WS";
    default:
        return "GET";
    }
}

QString Util::getBodyTypeString(BodyType type)
{
    switch (type) {
    case BodyType::JSON:
        return "JSON";
    case BodyType::XML:
        return "XML";
    case BodyType::MULTIPART_FORM:
        return "MULTIPART_FORM";
    case BodyType::URL_ENCODED_FORM:
        return "URL_ENCODED_FORM";
    default:
        return "None";
    }
}

QString Util::beautify(QString body, BodyType bodyType)
{
    if (bodyType == BodyType::JSON) {
        body = body.replace("\\t", "");
        auto doc = QJsonDocument::fromJson(body.toUtf8());

        return QString(doc.toJson(QJsonDocument::JsonFormat::Indented));
    }

    if (bodyType == BodyType::XML) {
        QString formatted;
        QXmlStreamReader reader(body);
        QXmlStreamWriter writer(&formatted);

        writer.setAutoFormatting(true);

        while (!reader.atEnd()) {
            reader.readNext();

            if (!reader.isWhitespace()) {
                writer.writeCurrentToken(reader);
            }
        }

        return formatted;
    }

    return body;
}

QString Util::beautify(QString body, QVariantMap headers)
{
    QString contentTypeHeader = getHeaderValue("Content-Type", headers);

    if (contentTypeHeader.contains("json")) {
        body = body.replace("\\t", "");
        auto doc = QJsonDocument::fromJson(body.toUtf8());

        return QString(doc.toJson(QJsonDocument::JsonFormat::Indented));
    }

    if (contentTypeHeader.contains("xml")) {
        QString formatted;
        QXmlStreamReader reader(body);
        QXmlStreamWriter writer(&formatted);

        writer.setAutoFormatting(true);

        while (!reader.atEnd()) {
            reader.readNext();

            if (!reader.isWhitespace()) {
                writer.writeCurrentToken(reader);
            }
        }

        return formatted;
    }

    if (contentTypeHeader.contains("html")) {
        // QTextDocument doc;
        // doc.setHtml(body);
        // doc.setIndentWidth(4);
        // doc.setTextWidth(40);

        // return doc.toHtml();


        QString result;
        QStack<QString> tagStack;
        int indentLevel = 0;

        QRegularExpression tagRegex("((<!--.*?-->)|(<[^>]*>)|([^<]+))");
        auto tagIterator = tagRegex.globalMatch(body);

        while (tagIterator.hasNext()) {
            QRegularExpressionMatch match = tagIterator.next();
            const QString tag = match.captured(0);

            if (tag[0] == '<') {
                // Tag (opening, closing, or self-closing)
                if (tag[1] == '/') {
                    // Closing tag
                    if (!tagStack.isEmpty()) {
                        tagStack.pop();
                        --indentLevel;
                    }
                }

                // Add indentation
                for (int i = 0; i < indentLevel; ++i) {
                    result.append("  ");
                }

                // Add the tag
                result.append(tag + '\n');

                if (tag[1] != '/' && tag[tag.length() - 2] != '/') {
                    // Opening tag, not self-closing
                    tagStack << tag;
                    ++indentLevel;
                }
            } else if (tag[0] == '<' && tag[1] == '!') {
                // Comment
                for (int i = 0; i < indentLevel; ++i) {
                    result.append("  ");
                }

                result.append(tag + '\n');
            } else {
                // Non-tag content
                // Add indentation
                for (int i = 0; i < indentLevel; ++i) {
                    // result.append("  ");
                }

                // Add the content
                // result.append(tag + '\n');
            }
        }

        return result;
    }

    return body;
}

QString Util::uuid() noexcept
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString Util::getHeaderValue(const QString& name, const QVariantMap& headers) noexcept
{
    QString lowerName = name.toLower();

    if (!headers.contains(name) && !headers.contains(lowerName)) {
        return "";
    }

    QString value = headers[name].toString();

    if (value.isEmpty()) {
        value = headers[lowerName].toString();
    }

    return value;
}

QJsonObject Util::getJsonFromFile(const QString& path) noexcept
{
    if (!QFile::exists(path)) {
        // emit error("File is not exists");

        return {};
    }

    QFile file(path);

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        // emit error("Read file error");

        return {};
    }

    QByteArray fileData = file.readAll();

    if (fileData.isEmpty()) {
        // emit error("File is empty");

        return {};
    }

    QJsonParseError jsonError;
    QJsonDocument json = QJsonDocument::fromJson(fileData, &jsonError);

    if (jsonError.error != QJsonParseError::NoError) {
        // emit error("Parse file error");

        return {};
    }

    return json.object();
}

void Util::writeJsonToFile(const QString& path, const QJsonObject& json) noexcept
{
    QFile file(path);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        // signal
        return;
    }

    QTextStream outStream(&file);
    outStream << QString(QJsonDocument(json).toJson());

    file.close();
}

double Util::round2digits(double num) noexcept
{
    return round(num * 100.0) / 100.0;
}

QVariantMap Util::getAnswerSize(qint64 bytesCount) noexcept
{
    QVariantMap result;

    if (bytesCount < 1024) {
        result["size"] = bytesCount;
        result["label"] = "B";
    } else if ((bytesCount / 1024) < 1024) {
        double cnt = static_cast<double>(bytesCount / 1024);
        result["size"] = round2digits(cnt);
        result["label"] = "Kb";
    } else {
        double cnt = static_cast<double>((bytesCount / 1024) / 1024);
        result["size"] = round2digits(cnt);
        result["label"] = "Mb";
    }

    return result;
}

QStringList Util::filterBigBody(const QString& body, const QString& searchString) noexcept
{
    auto doc = QJsonDocument::fromJson(body.toUtf8());
    QJsonObject json = doc.object();
    QStringList resultList;

    for (QJsonValueRef&& item : json) {
        optional<QJsonValue> value = findSubstring(item, searchString);

        if (value) {
            QJsonDocument doc(value->toObject());

            resultList << doc.toJson(QJsonDocument::Indented);
        }
    }

    return resultList;

    /*return body
            .split("\n")
            .filter(searchString);*/
}

// Рекурсивная функция для поиска подстроки в JSON
optional<QJsonValue> Util::findSubstring(const QJsonValue& value, const QString& substring, const QString& parentKey) {
    if (value.isObject()) {
        const QJsonObject obj = value.toObject();

        for (auto it = obj.begin(); it != obj.end(); ++it) {
            const QString key = it.key();
            const QJsonValue& val = it.value();

            QString valStr;

            if (val.isDouble()) {
                valStr = QString::number(val.toDouble());
            }

            if (val.isBool()) {
                valStr = val.toBool() ? "true" : "false";
            }

            if (val.isString()) {
                valStr = val.toString();
            }

            if (val.isNull()) {
                valStr = "null";
            }

            if (val.isUndefined()) {
                valStr = "undefined";
            }

            if (key.contains(substring, Qt::CaseInsensitive) || valStr.contains(substring, Qt::CaseInsensitive)) {
                // qDebug() << "Found at key:" << key << " value:" << val.toString();
                return { value };
            }

            return { findSubstring(val, substring, key) };
        }
    } else if (value.isArray()) {
        const QJsonArray arr = value.toArray();

        for (int i = 0; i < arr.size(); ++i) {
            const QJsonValue& val = arr[i];

            return { findSubstring(val, substring, parentKey) };
        }
    }

    return nullopt;
}
