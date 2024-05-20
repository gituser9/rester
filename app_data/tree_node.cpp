#include "tree_node.h"

TreeNode::TreeNode(TreeNode* parent)
{
    _parent = nullptr;

    if (parent != nullptr) {
        _parent = parent;
    }

    _nodeType = NodeType::QueryNode;
}

TreeNode::~TreeNode()
{
    qDeleteAll(_nodes);
    _nodes.clear();
}

QString TreeNode::uuid() const
{
    return _uuid;
}

void TreeNode::setUuid(const QString& newUuid)
{
    if (_uuid == newUuid) {
        return;
    }

    _uuid = newUuid;

    emit uuidChanged();
}

void TreeNode::addNode(TreeNode* node)
{
    node->setParent(this);
    _nodes << node;
}

void TreeNode::insertNode(qsizetype index, TreeNode* node)
{
    node->setParent(this);
    _nodes.insert(index, node);
}

void TreeNode::removeNode(TreeNode* node)
{
    qsizetype index = _nodes.indexOf(node);

    if (index != -1) {
        removeNode(index);
    }
}

void TreeNode::removeNode(qsizetype index)
{
    TreeNode* node = _nodes.at(index);
    delete node;

    _nodes.removeAt(index);
}

void TreeNode::softRemoveNode(qsizetype index)
{
    _nodes.removeAt(index);
}

void TreeNode::removeNodes()
{
    for (TreeNode* node : _nodes) {
        node->removeNodes();
    }

    qDeleteAll(_nodes);
    _nodes.clear();
}

void TreeNode::moveNode(qsizetype from, qsizetype to)
{
    _nodes.move(from, to);
}

void TreeNode::setParent(TreeNode* node)
{
    _parent = node;
}

bool TreeNode::isHasChild(TreeNode* child) const noexcept
{
    for (auto& node : _nodes) {
        if (child->uuid() == node->uuid()) {
            return true;
        }
    }

    return false;
}

QList<TreeNode*> TreeNode::nodes() noexcept
{
    return _nodes;
}

TreeNode* TreeNode::parent() const noexcept
{
    return _parent;
}

QString TreeNode::name() const
{
    return _name;
}

void TreeNode::setName(const QString& newName)
{
    if (_name == newName) {
        return;
    }

    _name = newName;

    emit nameChanged();
}

NodeType TreeNode::nodeType() const
{
    return _nodeType;
}

void TreeNode::setNodeType(NodeType newNodeType)
{
    if (_nodeType == newNodeType) {
        return;
    }

    _nodeType = newNodeType;

    emit nodeTypeChanged();
}
