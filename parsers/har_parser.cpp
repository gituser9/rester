#include "har_parser.h"

QList<Query*> HarParser::parse(const QJsonObject& json) const noexcept
{
    Har har(json);
    QList<Query*> queries;

    queries.reserve(har.entries.size());

    for (auto&& entry : har.entries) {
        queries << entry.request.toQuery();
    }

    return queries;
}
