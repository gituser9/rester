#ifndef WORSPACEMODEL_H
#define WORSPACEMODEL_H

#include <memory>

#include <QAbstractListModel>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QList>
#include <QScopedPointer>
#include <QSharedPointer>
#include <QStringView>
#include <QThread>

#include "../app_data/workspace.h"
#include "../importer.h"
#include "../saver.h"
#include "../util.h"

class WorkspaceModel : public QAbstractListModel {
    Q_OBJECT
    QML_SINGLETON

public:
    explicit WorkspaceModel(QObject* parent = nullptr);
    ~WorkspaceModel() override;

    // General
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    // Add/Delete:
    Q_INVOKABLE bool removeRows(int row, int count, const QModelIndex& parent = QModelIndex()) override;

    // Editable:
    bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    // Custom:
    Q_INVOKABLE void update(int idx, const QString& newName);
    Q_INVOKABLE void create(const QString& name);
    Q_INVOKABLE void loadWorkspaces();
    Q_INVOKABLE void exportCollection(const QString& folderPath, int index, int type) const;
    Q_INVOKABLE void setup() noexcept;
    Q_INVOKABLE void clean() noexcept;
    Q_INVOKABLE void importFrom(const QString& filePath, ImportType type);
    Q_INVOKABLE void exportTo(const QString& exportPath) const noexcept;
    Q_INVOKABLE void setVars(const QString& uuid, const QString& name, const QVariantMap& vars) noexcept;
    Q_INVOKABLE QVariantMap getVars(const QString& uuid, const QString& name) const noexcept;
    Q_INVOKABLE void setWorkspace(int index);

signals:
    void wsSave(std::shared_ptr<Workspace>);
    void wsUpdate(std::shared_ptr<Workspace>);
    void wsSet(std::shared_ptr<Workspace>);
    void error(const QString&);
    void varsUpdate(const QVariantMap& vars);

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    enum RoleNames {
        NameRole = Qt::UserRole,
        UuidRole = Qt::UserRole + 1,
        LastUsageRole = Qt::UserRole + 2
    };
    QHash<int, QByteArray> _names;
    QList<std::shared_ptr<Workspace>> _workspaces;
    QString _workspacesPath;
};

#endif // WORSPACEMODEL_H
