#ifndef INSOMNIAV5EXPORTER_H
#define INSOMNIAV5EXPORTER_H

#include <QString>
#include <QDateTime>
#include <QUuid>
#include <QSharedPointer>

#include <yaml-cpp/yaml.h>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

class InsomniaV5Exporter
{
public:
    static QString exportWorkspace(QSharedPointer<Workspace> workspace);

private:
    static void emitItem(YAML::Emitter& emitter, TreeNode* node);
    static void emitRequest(YAML::Emitter& emitter, Query* query);
    static void emitFolder(YAML::Emitter& emitter, Folder* folder);
    static void emitMeta(YAML::Emitter& emitter, const QString& prefix, const QString& uuid, bool isPrivate);
    static void emitKeyValueArray(YAML::Emitter& emitter, const QList<QueryParam>& list);
    static void emitFormArray(YAML::Emitter& emitter, const QList<QueryParam>& list);
    static void emitBody(YAML::Emitter& emitter, Query* query);
    static void emitSettings(YAML::Emitter& emitter);
    static QString generateId(const QString& prefix, const QString& uuid);
    static qint64 currentTimestamp();
};

#endif // INSOMNIAV5EXPORTER_H
