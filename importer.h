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

#include "app_data/constant.h"
#include "app_data/insomnia/insomnia.h"
#include "app_data/postman/postman.h"
#include "app_data/workspace.h"
#include "libs/import-lib/libimport.h"
#include "util.h"

class Importer : public QObject {
    Q_OBJECT

public:
    explicit Importer(QObject* parent = nullptr);

    QList<std::shared_ptr<Workspace>> import(const QString& filePath, ImportType type) noexcept;
    void exportWorkspaces(const QString& folderPath, const QString& exportPath) const noexcept;
    void exportCollection(QSharedPointer<Workspace> workspace, const QString& exportPath, ImportType type);

signals:
    void error(const QString&);

private:
    QList<std::shared_ptr<Workspace> > fromRester(const QString& folderPath) const noexcept;
    QList<std::shared_ptr<Workspace>> fromExternal(const QString& filePath, ImportType type) noexcept;

    QSharedPointer<Insomnia> toInsomniaCollection(QSharedPointer<Workspace> ws) const noexcept;
    QSharedPointer<PostmanCollection> toPostmanCollection(QSharedPointer<Workspace> ws) const noexcept;
};

#endif // IMPORTER_H
