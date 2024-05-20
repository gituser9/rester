#include "postman_request_body.h"

QJsonObject PostmanRequestBody::toJson() const
{
    QJsonObject bodyObject = {
        { "mode", mode },
        { "raw", raw },
    };

    if (!formdata.isEmpty()) {
        QJsonArray formDataArr;

        for (const PostmanFormDataBody& formItem : formdata) {
            QJsonObject itemObj;

            if (formItem.value.startsWith("file://")) {
                itemObj["type"] = "file";

                if (formItem.value.startsWith("file://")) {
                    QString val = formItem.value;
                    itemObj["src"] = val.replace("file://", "");
                }
            } else {
                itemObj["type"] = "text";
            }

            itemObj["key"] = formItem.key;
            itemObj["value"] = formItem.value;

            formDataArr << itemObj;
        }

        bodyObject["formdata"] = formDataArr;
    } else {
        bodyObject["options"] = options.toJson();
    }

    return bodyObject;
}