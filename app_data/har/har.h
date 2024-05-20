#ifndef __HAR_H__
#define __HAR_H__

#include <QJsonArray>
#include <QJsonObject>
#include <QList>
#include <QString>

#include "har_request.h"

struct HarEntry {
    HarRequest request;

    HarEntry(HarRequest&& req)
    {
        request = req;
    }
};

struct HarLogCreator {
    QString name;
    QString version;
};

struct HarBrowser {
    QString name;
    QString version;
};

struct HarPage {
    QString id;
};

struct HarLog {
    QString version;
    HarLogCreator creator;
    HarBrowser browser;
    QList<HarPage> pages;
    QList<HarEntry> entries;
};


class Har {
public:
    Har();
    Har(const QJsonObject& json);


    HarLog log;
    QList<HarEntry> entries;
};

#endif // __HAR_H__
