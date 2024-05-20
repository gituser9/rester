#include "folder.h"
#include "query.h"

Folder::Folder(TreeNode* parent)
    : TreeNode(parent)
{
    _isExpanded = false;
}

bool Folder::isExpanded() const
{
    return _isExpanded;
}

void Folder::setIsExpanded(bool newIsExpanded)
{
    if (_isExpanded == newIsExpanded) {
        return;
    }

    _isExpanded = newIsExpanded;

    emit isExpandedChanged();
}

QList<InsomniaResource> Folder::toInsomniaResource(const QString& parentId, Folder* fld) noexcept
{
    if (fld == nullptr) {
        fld = this;
    }

    // to ctor
    auto millis = QDateTime::currentMSecsSinceEpoch();
    InsomniaResource resource;
    resource.id = "fld_" + Util::uuid();
    resource.parentId = parentId;
    resource.modified = millis;
    resource.created = millis;
    resource.name = fld->name();
    resource.type = "request_group";

    QList<InsomniaResource> resources;
    resources << resource;

    for (TreeNode* item : fld->nodes()) {
        auto node = static_cast<TreeNode*>(item);

        if (node->nodeType() == NodeType::FolderNode) {
            auto childFld = static_cast<Folder*>(node);
            QList<InsomniaResource> childResources = toInsomniaResource(resource.id, childFld);
            resources << childResources;
        } else if (node->nodeType() == NodeType::QueryNode) {
            auto qry = static_cast<Query*>(node);
            InsomniaResource childResource = qry->toInsomniaResource(resource.id);

            resources << childResource;
        }
    }

    return resources;
}

QList<PostmanItem> Folder::toPostmanItem(Folder* fld) noexcept
{
    if (fld == nullptr) {
        fld = this;
    }

    PostmanItem item;
    item.name = fld->name();

    QList<PostmanItem> items;

    for (TreeNode* node : fld->nodes()) {
        if (node->nodeType() == NodeType::FolderNode) {
            auto childFld = qobject_cast<Folder*>(node);
            QList<PostmanItem> childItems = toPostmanItem(childFld);

            item.items << childItems;
        } else if (node->nodeType() == NodeType::QueryNode) {
            auto qry = qobject_cast<Query*>(node);
            item.items << qry->toPostmanItem();
        }
    }

    items.prepend(item);

    return items;
}
