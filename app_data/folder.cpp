#include "folder.h"
#include "query.h"

Folder::Folder(TreeNode* parent) : TreeNode(parent)
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
