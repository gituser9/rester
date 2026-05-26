#include "routes_filter_proxy.h"

RoutesFilterModel::RoutesFilterModel(QObject* parent) : QSortFilterProxyModel(parent)
{
    setRecursiveFilteringEnabled(true);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
}

void RoutesFilterModel::setFilterText(const QString& text)
{
    // setFilterFixedString(text);

    if (_filterText == text) {
        return;
    }

    _filterText = text;

    setFilterRegularExpression(QRegularExpression::escape(text));
}

#define DELEGATE_VOID(Method, ...)                             \
    if (auto* src = qobject_cast<RoutesModel*>(sourceModel())) \
        src->Method(__VA_ARGS__);

void RoutesFilterModel::addFolder(const QString& name, const QModelIndex& parentProxyIdx)
{
    DELEGATE_VOID(addFolder, name, mapToSource(parentProxyIdx))
}

void RoutesFilterModel::addQuery(const QString& name, const QString& type, const QModelIndex& parentProxyIdx)
{
    DELEGATE_VOID(addQuery, name, type, mapToSource(parentProxyIdx))
}

bool RoutesFilterModel::removeRows(int row, int count, const QModelIndex& parentProxyIdx)
{
    if (auto* src = qobject_cast<RoutesModel*>(sourceModel())) {
        return src->removeRows(row, count, mapToSource(parentProxyIdx));
    }

    return false;
}

bool RoutesFilterModel::moveRows(const QModelIndex& sourceProxyIdx, int sourceRow, int count, const QModelIndex& destProxyIdx, int destChild)
{
    if (auto* src = qobject_cast<RoutesModel*>(sourceModel())) {
        return src->moveRows(mapToSource(sourceProxyIdx), sourceRow, count, mapToSource(destProxyIdx), destChild);
    }

    return false;
}

void RoutesFilterModel::updateFolder(const QModelIndex& proxyIdx, const QVariant& value, int role)
{
    DELEGATE_VOID(updateFolder, mapToSource(proxyIdx), value, role)
}

void RoutesFilterModel::updateQuery(const QModelIndex& proxyIdx, const QVariant& value, int role)
{
    DELEGATE_VOID(updateQuery, mapToSource(proxyIdx), value, role)
}

void RoutesFilterModel::setCurrentQuery(const QModelIndex& proxyIdx)
{
    DELEGATE_VOID(setCurrentQuery, mapToSource(proxyIdx))
}

void RoutesFilterModel::toggleFolderExpanded(const QModelIndex& proxyIdx)
{
    DELEGATE_VOID(toggleFolderExpanded, mapToSource(proxyIdx))
}

bool RoutesFilterModel::isFolderExpanded(const QModelIndex& proxyIdx) const
{
    if (auto* src = qobject_cast<RoutesModel*>(sourceModel())) {
        return src->isFolderExpanded(mapToSource(proxyIdx));
    }

    return false;
}

void RoutesFilterModel::downloadBigAnswer(const QString& dirPath, Query* qry) const
{
    if (auto* src = qobject_cast<RoutesModel*>(sourceModel())) {
        src->downloadBigAnswer(dirPath, qry);
    }
}

void RoutesFilterModel::importFromHar(const QModelIndex& parentProxyIdx, const QString& filePath){DELEGATE_VOID(importFromHar, mapToSource(parentProxyIdx), filePath)}

QString RoutesFilterModel::copyAsCurl(const QModelIndex& proxyIdx) const
{
    if (auto* src = qobject_cast<RoutesModel*>(sourceModel())) {
        return src->copyAsCurl(mapToSource(proxyIdx));
    }

    return {};
}

bool RoutesFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const
{
    if (_filterText.isEmpty()) {
        return true;
    }

    QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);

    if (!sourceIndex.isValid()) {
        return false;
    }

    auto node = static_cast<TreeNode*>(sourceIndex.internalPointer());

    if (!node) {
        return false;
    }

    // Name (Folder / Query / GrpcQuery)
    if (node->name().contains(_filterText, Qt::CaseInsensitive)) {
        return true;
    }

    // URL (Query)
    if (node->nodeType() == NodeType::QueryNode) {
        auto qry = static_cast<Query*>(node);

        if (qry && qry->url().contains(_filterText, Qt::CaseInsensitive)) {
            return true;
        }
    }

    return false;
}
