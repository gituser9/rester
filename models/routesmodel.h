#pragma clang diagnostic push
#pragma ide diagnostic ignored "modernize-use-nodiscard"
#ifndef ROUTESMODEL_H
#define ROUTESMODEL_H

#include <iostream>
#include <memory>

#include <QAbstractItemModel>
#include <QByteArray>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QList>
#include <QSharedPointer>
#include <QStandardItem>
#include <QThread>
#include <QUuid>
#include <qqml.h>

#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../app_data/workspace.h"
#include "../importer.h"
#include "../parsers/curl_parser.h"
#include "../parsers/har_parser.h"
#include "../saver.h"
#include "../settings.h"

class RoutesModel : public QAbstractItemModel {
    Q_OBJECT
//    QML_ELEMENT
//    QML_SINGLETON

public:
    explicit RoutesModel(QObject* parent = nullptr);
    virtual ~RoutesModel();

    // Basic functionality:
    QModelIndex index(int row, int column, const QModelIndex& parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex& index) const override;

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    int columnCount(const QModelIndex& parent = QModelIndex()) const override;
    Q_INVOKABLE virtual bool hasChildren(const QModelIndex& parent = QModelIndex()) const override;

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Editable:
    Q_INVOKABLE bool removeRows(int row, int count, const QModelIndex& parent = QModelIndex()) override;
    Q_INVOKABLE bool moveRows(const QModelIndex& sourceParent, int sourceRow, int count, const QModelIndex& destinationParent, int destinationChild) override;
    bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;
    bool canFetchMore(const QModelIndex& parent) const override;
    Qt::ItemFlags flags(const QModelIndex& index) const override;

    // Custom:
    Q_INVOKABLE void addFolder(QString name, const QModelIndex& parentIdx);
    Q_INVOKABLE void addQuery(QString name, const QModelIndex& parentIdx);
    Q_INVOKABLE void addQuery(QString name, QString type, const QModelIndex& parentIdx);
    Q_INVOKABLE void updateFolder(const QModelIndex& index, const QVariant& value, int role);
    Q_INVOKABLE void toggleFolderExpanded(const QModelIndex& idx);
    Q_INVOKABLE void updateQuery(const QModelIndex& index, const QVariant& value, int role);
    Q_INVOKABLE void setCurrentQuery(const QModelIndex& idx);
    Q_INVOKABLE void downloadBigAnswer(QString dirPath, Query const* qry) const noexcept;
    Q_INVOKABLE void importFromHar(const QModelIndex& parentIdx, const QString& filePath) noexcept;
    Q_INVOKABLE QString copyAsCurl(const QModelIndex& idx) const;
    Q_INVOKABLE QVariantMap getFolders() const;

public slots:
    void loadTree(std::shared_ptr<Workspace> workspace) noexcept;

signals:
    void queryChanged();
    void treeChanged(std::shared_ptr<Workspace>);
    void moderError(QString);
    void error(const QString&);
    void setQuery(Query*);
    void queryRemoved(const QString&);

private:
    enum RoleType {
        NameRole = Qt::UserRole,
        NodeTypeRole,
        QueryTypeRole,
        FolderExpandedRole,
        UuidRole,
        ParentUuidRole,
    };
    std::shared_ptr<Workspace> _currentWorkspace;
    QHash<int, QByteArray> _names;

    TreeNode* getItem(const QModelIndex& idx) const noexcept;
    QString getQueryTypeFromNode(TreeNode* node) const noexcept;
    bool getExpandedFromNode(TreeNode* node) const noexcept;
};

#endif // ROUTESMODEL_H

#pragma clang diagnostic pop
