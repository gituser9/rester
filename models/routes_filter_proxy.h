#ifndef ROUTES_FILTER_PROXY_H
#define ROUTES_FILTER_PROXY_H

#include <QSortFilterProxyModel>
#include <qqml.h>

#include "routesmodel.h"

class RoutesFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit RoutesFilterModel(QObject* parent = nullptr);

    Q_INVOKABLE void setFilterText(const QString& text);

    // Delegates
    Q_INVOKABLE void addFolder(const QString& name, const QModelIndex& parentProxyIdx);
    Q_INVOKABLE void addQuery(const QString& name, const QString& type, const QModelIndex& parentProxyIdx);
    Q_INVOKABLE bool removeRows(int row, int count, const QModelIndex& parentProxyIdx) override;
    Q_INVOKABLE bool moveRows(const QModelIndex& sourceProxyIdx, int sourceRow, int count, const QModelIndex& destProxyIdx, int destChild) override;
    Q_INVOKABLE void updateFolder(const QModelIndex& proxyIdx, const QVariant& value, int role);
    Q_INVOKABLE void updateQuery(const QModelIndex& proxyIdx, const QVariant& value, int role);
    Q_INVOKABLE void setCurrentQuery(const QModelIndex& proxyIdx);
    Q_INVOKABLE void toggleFolderExpanded(const QModelIndex& proxyIdx);
    Q_INVOKABLE bool isFolderExpanded(const QModelIndex& proxyIdx) const;
    Q_INVOKABLE void downloadBigAnswer(const QString& dirPath, Query* qry) const;
    Q_INVOKABLE void importFromHar(const QModelIndex& parentProxyIdx, const QString& filePath);
    Q_INVOKABLE QString copyAsCurl(const QModelIndex& proxyIdx) const;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override;

private:
    QString _filterText;
};

#endif // ROUTES_FILTER_PROXY_H
