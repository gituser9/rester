#include "har_post_data.h"

HarPostData HarPostData::fromJson(QJsonObject&& json) noexcept
{
    HarPostData data;
    data.mimeType = json.value("mimeType").toString();
    data.text = json.value("text").toString();

    return data;
}
