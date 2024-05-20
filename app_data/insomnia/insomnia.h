#ifndef INSOMNIA_H
#define INSOMNIA_H

#include <memory>

#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QList>
#include <QString>

const QString InsomniaWorkspacePrefix = "wrk_";
const QString InsomniaFolderPrefix = "fld_";
const QString InsomniaQueryPrefix = "req_";

class InsomniaParam {
public:
    QString name;
    QString value;
    QString description;
    QString id;
    QString type;
    QString fileName;
    bool disabled;

    static InsomniaParam fromJson(const QJsonObject& json)
    {
        InsomniaParam param;

        param.name = json["name"].toString();
        param.value = json["value"].toString();
        param.description = json["description"].toString();
        param.id = json["id"].toString();
        param.type = json["type"].toString();
        param.fileName = json["fileName"].toString();
        param.disabled = json["disabled"].toBool();

        return param;
    }

    QJsonValue toJson() const noexcept
    {
        QJsonObject paramObject = {
            { "name", name },
            { "value", value },
            { "type", type },
            { "fileName", fileName },
            { "id", id },
            { "disabled", disabled },
            { "description", description },
        };

        return paramObject;
    }
};

class InsomniaHeader {
public:
    QString name;
    QString value;
    QString id;
    QString description;
    bool disabled;

    static InsomniaHeader fromJson(const QJsonObject& json)
    {
        InsomniaHeader header;
        header.name = json["name"].toString();
        header.value = json["value"].toString();
        header.id = json["id"].toString();
        header.description = json["description"].toString();
        header.disabled = json["disabled"].toBool();

        return header;
    }

    QJsonValue toJson() const noexcept
    {
        QJsonObject paramObject = {
            { "name", name },
            { "value", value },
            { "id", id },
            { "disabled", disabled },
            { "description", description },
        };

        return paramObject;
    }
};

class InsomniaBody {
public:
    QString mimeType;
    QString text;
    QList<InsomniaParam> params;

    static InsomniaBody fromJson(const QJsonObject& json)
    {
        InsomniaBody body;

        body.mimeType = json["mimeType"].toString();
        body.text = json["text"].toString();

        for (QJsonValueRef&& param : json["params"].toArray()) {
            body.params << InsomniaParam::fromJson(param.toObject());
        }

        return body;
    }

    QJsonValue toJson() const noexcept
    {
        QJsonObject paramObject = {
            { "mimeType", mimeType },
            { "text", text },
        };
        QJsonArray paramArr;

        for (const InsomniaParam& param : params) {
            paramArr << param.toJson();
        }

        if (!paramArr.isEmpty()) {
            paramObject["params"] = paramArr;
        }

        return paramObject;
    }
};

class InsomniaResource {
public:
    QString id;
    QString parentId;
    QString url;
    QString name;
    QString description;
    QString method;
    QString settingFollowRedirects;
    QString type;
    QString scope;
    QString fileName;
    QString contents;
    QString contentType;
    QString value;
    QString mode;
    qint64 modified;
    qint64 created;
    QList<InsomniaHeader> parameters;
    QList<InsomniaHeader> headers;
    double metaSortKey;
    bool isPrivate;
    bool settingStoreCookies;
    bool settingSendCookies;
    bool settingDisableRenderRequestBody;
    bool settingEncodeUrl;
    bool settingRebuildPath;
    QVariant environmentPropertyOrder;
    QVariant color;
    QSharedPointer<InsomniaBody> body = QSharedPointer<InsomniaBody>(new InsomniaBody);

    static InsomniaResource fromJson(const QJsonObject& json)
    {
        QString id = json["_id"].toString();
        InsomniaResource res;

        // folder
        if (id.startsWith(InsomniaFolderPrefix)) {
            res.id = id;
            res.parentId = json["parentId"].toString();
            res.modified = json["modified"].toInteger();
            res.created = json["created"].toInteger();
            res.name = json["name"].toString();
            res.type = json["_type"].toString();
            res.metaSortKey = json["metaSortKey"].toDouble();
        }
        // query
        else if (id.startsWith(InsomniaQueryPrefix)) {
            auto body = InsomniaBody::fromJson(json["body"].toObject());

            for (QJsonValueConstRef&& header : json["headers"].toArray()) {
                res.headers << InsomniaHeader::fromJson(header.toObject());
            }

            for (QJsonValueConstRef&& param : json["headers"].toArray()) {
                res.parameters << InsomniaHeader::fromJson(param.toObject());
            }

            res.id = id;
            res.parentId = json["parentId"].toString();
            res.modified = json["modified"].toInteger();
            res.created = json["created"].toInteger();
            res.name = json["name"].toString();
            res.method = json["method"].toString();
            res.url = json["url"].toString();
            res.body = QSharedPointer<InsomniaBody>(&body);

            res.isPrivate = json["isPrivate"].toBool();
            res.settingStoreCookies = json["settingStoreCookies"].toBool();
            res.settingSendCookies = json["settingSendCookies"].toBool();
            res.settingDisableRenderRequestBody = json["settingDisableRenderRequestBody"].toBool();
            res.settingEncodeUrl = json["settingEncodeUrl"].toBool();
            res.settingRebuildPath = json["settingRebuildPath"].toBool();
            res.settingFollowRedirects = json["settingFollowRedirects"].toString();
        }
        // workspace
        else if (id.startsWith(InsomniaWorkspacePrefix)) {
            res.id = id;
            res.modified = json["modified"].toInteger();
            res.created = json["created"].toInteger();
            res.name = json["name"].toString();
            res.type = "workspace";
            res.scope = "collection";
        }

        return res;
    }

    QJsonObject toJson() const noexcept
    {
        // folder
        if (id.startsWith(InsomniaFolderPrefix)) {
            return {
                { "_id", id },
                { "parentId", parentId },
                { "modified", modified },
                { "created", created },
                { "name", name },
                { "_type", type },
                { "metaSortKey", -created },
            };
        }
        // query
        else if (id.startsWith(InsomniaQueryPrefix)) {
            QJsonArray params, hdrs;

            for (const InsomniaHeader& param : parameters) {
                params << param.toJson();
            }

            for (const InsomniaHeader& param : headers) {
                hdrs << param.toJson();
            }

            return {
                { "_id", id },
                { "parentId", parentId },
                { "modified", modified },
                { "created", created },
                { "name", name },
                { "_type", "request" },
                { "url", url },
                { "method", method },
                { "parameters", params },
                { "headers", hdrs },
                { "body", body->toJson() },
                { "metaSortKey", -created },
                { "isPrivate", false },
                { "settingStoreCookies", true },
                { "settingSendCookies", true },
                { "settingDisableRenderRequestBody", false },
                { "settingEncodeUrl", true },
                { "settingRebuildPath", true },
                { "settingFollowRedirects", "global" },
            };
        }
        // workspace
        else if (id.startsWith(InsomniaWorkspacePrefix)) {
            return {
                { "_id", id },
                { "parentId", QJsonValue::Null },
                { "modified", modified },
                { "created", created },
                { "name", name },
                { "_type", "workspace" },
                { "scope", "collection" },
            };
        }

        return {};
    }
};

class Insomnia {
public:
    QString type;
    QString exportDate;
    QString exportSource;
    QList<InsomniaResource> resources;
    qint64 exportFormat;

    static Insomnia fromJson(const QJsonObject& json)
    {
        Insomnia insomnia;
        insomnia.type = json["_type"].toString();
        insomnia.exportDate = json["__export_date"].toString();
        insomnia.exportSource = json["__export_source"].toString();
        insomnia.exportFormat = json["__export_format"].toInteger();

        QJsonArray resources = json["resources"].toArray();
        insomnia.resources.reserve(resources.size());

        for (QJsonValueRef&& res : resources) {
            insomnia.resources << InsomniaResource::fromJson(res.toObject());
        }

        return insomnia;
    }

    QJsonObject toJson() const noexcept
    {
        QJsonArray resourceArr;

        for (const InsomniaResource& resource : resources) {
            if (resource.id.isEmpty()) {
                continue;
            }

            resourceArr << resource.toJson();
        }

        return {
            { "_type", type },
            { "__export_format", exportFormat },
            { "__export_date", exportDate },
            { "__export_source", exportSource },
            { "resources", resourceArr }
        };
    }
};

#endif // INSOMNIA_H
