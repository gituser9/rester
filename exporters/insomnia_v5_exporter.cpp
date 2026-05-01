#include "insomnia_v5_exporter.h"

#include "insomnia_v5_exporter.h"

QString InsomniaV5Exporter::exportWorkspace(QSharedPointer<Workspace> workspace)
{
    if (!workspace) {
        return {};
    }

    YAML::Emitter emitter;
    emitter.SetIndent(2);
    emitter.SetMapFormat(YAML::Block);
    emitter.SetSeqFormat(YAML::Block);
    emitter.SetBoolFormat(YAML::TrueFalseBool);

    emitter << YAML::BeginMap;
    emitter << YAML::Key << "type" << YAML::Value << "collection.insomnia.rest/5.0";
    emitter << YAML::Key << "schema_version" << YAML::Value << YAML::DoubleQuoted << "5.1";
    emitter << YAML::Key << "name" << YAML::Value << workspace->name().toStdString();

    // meta
    emitter << YAML::Key << "meta";
    emitter << YAML::Value;
    emitter << YAML::BeginMap;

    const qint64 wsNow = currentTimestamp();

    emitter << YAML::Key << "id" << YAML::Value
            << generateId("wrk_", workspace->uuid()).toStdString();
    emitter << YAML::Key << "created" << YAML::Value << wsNow;
    emitter << YAML::Key << "modified" << YAML::Value << wsNow;
    emitter << YAML::Key << "description" << YAML::Value << "";
    emitter << YAML::EndMap;

    // collection
    emitter << YAML::Key << "collection";
    emitter << YAML::Value << YAML::BeginSeq;

    const auto rootNodes = workspace->nodes();

    for (TreeNode* node : rootNodes) {
        emitItem(emitter, node);
    }

    emitter << YAML::EndSeq;

    // cookieJar
    emitter << YAML::Key << "cookieJar";
    emitter << YAML::Value;
    emitter << YAML::BeginMap;
    emitter << YAML::Key << "name" << YAML::Value << "Default Jar";
    emitter << YAML::Key << "meta";
    emitter << YAML::Value << YAML::BeginMap;

    const QString jarId = generateId("jar_", QUuid::createUuid().toString(QUuid::WithoutBraces));
    const qint64 jarNow = currentTimestamp();

    emitter << YAML::Key << "id" << YAML::Value << jarId.toStdString();
    emitter << YAML::Key << "created" << YAML::Value << jarNow;
    emitter << YAML::Key << "modified" << YAML::Value << jarNow;
    emitter << YAML::EndMap; // meta
    emitter << YAML::EndMap; // cookieJar

    // environments
    emitter << YAML::Key << "environments";
    emitter << YAML::Value;
    emitter << YAML::BeginMap;
    emitter << YAML::Key << "name" << YAML::Value << "Base Environment";
    emitter << YAML::Key << "meta";
    emitter << YAML::Value << YAML::BeginMap;

    const QString envId = generateId("env_", QUuid::createUuid().toString(QUuid::WithoutBraces));
    const qint64 envNow = currentTimestamp();

    emitter << YAML::Key << "id" << YAML::Value << envId.toStdString();
    emitter << YAML::Key << "created" << YAML::Value << envNow;
    emitter << YAML::Key << "modified" << YAML::Value << envNow;
    emitter << YAML::Key << "isPrivate" << YAML::Value << false;
    emitter << YAML::EndMap; // meta
    emitter << YAML::Key << "subEnvironments" << YAML::Value << YAML::BeginSeq << YAML::EndSeq;
    emitter << YAML::EndMap; // environments

    emitter << YAML::EndMap; // root

    return QString::fromStdString(emitter.c_str());
}

void InsomniaV5Exporter::emitItem(YAML::Emitter& emitter, TreeNode* node)
{
    if (!node) {
        return;
    }

    if (node->nodeType() == NodeType::FolderNode) {
        auto folder = static_cast<Folder*>(node);
        emitFolder(emitter, folder);
    }
    else if (node->nodeType() == NodeType::QueryNode) {
        auto query = static_cast<Query*>(node);
        emitRequest(emitter, query);
    }
}

void InsomniaV5Exporter::emitFolder(YAML::Emitter& emitter, Folder* folder)
{
    emitter << YAML::BeginMap;
    emitter << YAML::Key << "name" << YAML::Value << folder->name().toStdString();
    emitter << YAML::Key << "meta";
    emitter << YAML::Value;
    emitMeta(emitter, "fld_", folder->uuid(), false);

    const auto children = folder->nodes();

    if (!children.isEmpty()) {
        emitter << YAML::Key << "children";
        emitter << YAML::Value << YAML::BeginSeq;

        for (TreeNode* child : children) {
            emitItem(emitter, child);
        }

        emitter << YAML::EndSeq;
    }

    emitter << YAML::EndMap;
}

void InsomniaV5Exporter::emitRequest(YAML::Emitter& emitter, Query* query)
{
    emitter << YAML::BeginMap;
    emitter << YAML::Key << "url" << YAML::Value << query->url().toStdString();
    emitter << YAML::Key << "name" << YAML::Value << query->name().toStdString();

    emitter << YAML::Key << "meta";
    emitter << YAML::Value;
    emitMeta(emitter, "req_", query->uuid(), true);

    emitter << YAML::Key << "method" << YAML::Value << Util::getQueryTypeString(query->queryType()).toStdString();

    // headers
    const QList<QueryParam>& headers = query->headerList();

    if (!headers.isEmpty()) {
        emitter << YAML::Key << "headers";
        emitter << YAML::Value;
        emitKeyValueArray(emitter, headers);
    }

    // parameters
    const QList<QueryParam>& params = query->paramList();

    if (!params.isEmpty()) {
        emitter << YAML::Key << "parameters";
        emitter << YAML::Value;
        emitKeyValueArray(emitter, params);
    }

    // body
    if (query->bodyType() != BodyType::NONE) {
        emitter << YAML::Key << "body";
        emitter << YAML::Value;
        emitBody(emitter, query);
    }

    // settings
    emitter << YAML::Key << "settings";
    emitter << YAML::Value;
    emitSettings(emitter);

    emitter << YAML::EndMap;
}

void InsomniaV5Exporter::emitMeta(YAML::Emitter& emitter, const QString& prefix, const QString& uuid, bool isPrivate)
{
    emitter << YAML::BeginMap;
    emitter << YAML::Key << "id" << YAML::Value << generateId(prefix, uuid).toStdString();

    const qint64 now = currentTimestamp();

    emitter << YAML::Key << "created" << YAML::Value << now;
    emitter << YAML::Key << "modified" << YAML::Value << now;

    if (isPrivate) {
        emitter << YAML::Key << "isPrivate" << YAML::Value << false;
    }

    emitter << YAML::Key << "description" << YAML::Value << "";
    emitter << YAML::Key << "sortKey" << YAML::Value << -now;
    emitter << YAML::EndMap;
}

void InsomniaV5Exporter::emitKeyValueArray(YAML::Emitter& emitter, const QList<QueryParam>& list)
{
    emitter << YAML::BeginSeq;

    for (const QueryParam& param : list) {
        emitter << YAML::BeginMap;
        emitter << YAML::Key << "name" << YAML::Value << param.name().toStdString();
        emitter << YAML::Key << "value" << YAML::Value << YAML::DoubleQuoted << param.value().toStdString();
        emitter << YAML::Key << "description" << YAML::Value << "";
        emitter << YAML::Key << "disabled" << YAML::Value << !param.isEnabled();
        emitter << YAML::EndMap;
    }

    emitter << YAML::EndSeq;
}

void InsomniaV5Exporter::emitFormArray(YAML::Emitter& emitter, const QList<QueryParam>& list)
{
    emitter << YAML::BeginSeq;

    for (const QueryParam& param : list) {
        emitter << YAML::BeginMap;
        emitter << YAML::Key << "name" << YAML::Value << param.name().toStdString();

        if (param.value().startsWith("file://")) {
            emitter << YAML::Key << "value" << YAML::Value << YAML::DoubleQuoted << "";
            emitter << YAML::Key << "filename" << YAML::Value << param.value().replace("file://", "").toStdString();
            emitter << YAML::Key << "type" << YAML::Value << "file";
        }
        else {
            emitter << YAML::Key << "value" << YAML::Value << YAML::DoubleQuoted << param.value().toStdString();
        }

        emitter << YAML::Key << "description" << YAML::Value << "";
        emitter << YAML::Key << "disabled" << YAML::Value << !param.isEnabled();
        emitter << YAML::EndMap;
    }

    emitter << YAML::EndSeq;
}

void InsomniaV5Exporter::emitBody(YAML::Emitter& emitter, Query* query)
{
    emitter << YAML::BeginMap;

    const BodyType type = query->bodyType();
    QString mimeType;

    switch (type) {
    case BodyType::JSON:
        mimeType = "application/json";
        break;
    case BodyType::XML:
        mimeType = "application/xml";
        break;
    case BodyType::URL_ENCODED_FORM:
        mimeType = "application/x-www-form-urlencoded";
        break;
    case BodyType::MULTIPART_FORM:
        mimeType = "multipart/form-data";
        break;
    default:
        mimeType = "text/plain";
    }

    emitter << YAML::Key << "mimeType" << YAML::Value << mimeType.toStdString();

    const QString text = query->body();

    if (type == BodyType::JSON || type == BodyType::XML || type == BodyType::URL_ENCODED_FORM) {
        if (!text.isEmpty()) {
            emitter << YAML::Key << "text";

            if (text.contains('\n')) {
                emitter << YAML::Value << YAML::Literal << text.toStdString();
            }
            else {
                emitter << YAML::Value << text.toStdString();
            }
        }
    }
    else if (type == BodyType::MULTIPART_FORM) {
        auto formData = query->formDataList();

        if (!formData.isEmpty()) {
            emitter << YAML::Key << "params";
            emitter << YAML::Value;
            emitFormArray(emitter, formData);
        }
    }

    emitter << YAML::EndMap;
}

void InsomniaV5Exporter::emitSettings(YAML::Emitter& emitter)
{
    emitter << YAML::BeginMap;
    emitter << YAML::Key << "renderRequestBody" << YAML::Value << true;
    emitter << YAML::Key << "encodeUrl" << YAML::Value << true;
    emitter << YAML::Key << "followRedirects" << YAML::Value << "global";
    emitter << YAML::Key << "cookies";
    emitter << YAML::Value << YAML::BeginMap;
    emitter << YAML::Key << "send" << YAML::Value << true;
    emitter << YAML::Key << "store" << YAML::Value << true;
    emitter << YAML::EndMap;
    emitter << YAML::Key << "rebuildPath" << YAML::Value << true;
    emitter << YAML::EndMap;
}

QString InsomniaV5Exporter::generateId(const QString& prefix, const QString& uuid)
{
    QString clean = uuid;
    clean.remove('{').remove('}').remove('-');

    // Insomnia uses exactly 32 characters after the prefix
    QString hexPart = clean.left(32);

    return prefix + hexPart;
}

qint64 InsomniaV5Exporter::currentTimestamp()
{
    return QDateTime::currentMSecsSinceEpoch();
}
