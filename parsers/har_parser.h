#ifndef HAR_PARSER_H
#define HAR_PARSER_H

#include <QJsonArray>
#include <QJsonObject>
#include <QList>

#include "../app_data/har/har.h"
#include "../app_data/query.h"
#include "../util.h"

class HarParser {
public:
    QList<Query*> parse(const QJsonObject& json) const noexcept;
    Har generate(Folder* folder) noexcept;

private:
};

#endif
