#include "har.h"

Har::Har()
{
}

Har::Har(const QJsonObject& json)
{
    QJsonValue logObject = json["log"];
    QJsonArray jsonEntries = logObject["entries"].toArray();

    entries.reserve(jsonEntries.count());

    for (auto&& entry : jsonEntries) {
        QJsonObject requestObject = entry.toObject();
        auto request = HarRequest::fromJson(requestObject["request"].toObject());

        entries << HarEntry(std::move(request));
    }
}
