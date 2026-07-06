#ifndef IMPORTER_H
#define IMPORTER_H

#include <memory>

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSharedPointer>
#include <QString>
#include <QList>

#include "util.h"
#include "app_data/constant.h"
#include "app_data/workspace.h"
#include "importers/swagger_importer.h"
#include "importers/postman_importer.h"
#include "importers/insomnia_v5_importer.h"
#include "importers/har_importer.h"
#include "exporters/postman_exporter.h"
#include "exporters/insomnia_v5_exporter.h"
#include "exporters/har_exporter.h"

class Importer : public QObject
{
    Q_OBJECT

public:
    explicit Importer(QObject* parent = nullptr);

    std::shared_ptr<Workspace> importWorkspace(const QString& filePath, RstEnums::ImportType type) noexcept;
    void exportWorkspaces(const QString& folderPath, const QString& exportPath) const noexcept;
    void exportCollection(QSharedPointer<Workspace> workspace, const QString& exportPath, RstEnums::ImportType type);

signals:
    void error(const QString&);

private:
    std::shared_ptr<Workspace> fromRester(const QString& folderPath) const noexcept;
    std::shared_ptr<Workspace> fromExternal(const QString& filePath, RstEnums::ImportType type) noexcept;
};

#endif // IMPORTER_H
