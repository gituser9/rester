#ifndef __HAR_POST_DATA_H__
#define __HAR_POST_DATA_H__

#include <QJsonObject>
#include <QString>

struct HarPostData {
    QString mimeType;
    QString text;

    static HarPostData fromJson(QJsonObject&& json) noexcept;
};

#endif // __HAR_POST_DATA_H__
