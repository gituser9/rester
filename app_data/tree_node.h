#ifndef TREE_NODE_H
#define TREE_NODE_H

#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QString>

#include "constant.h"

class TreeNode : public QObject {
    Q_OBJECT

    Q_PROPERTY(NodeType nodeType READ nodeType WRITE setNodeType NOTIFY nodeTypeChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString uuid READ uuid WRITE setUuid NOTIFY uuidChanged)

public:
    explicit TreeNode(TreeNode* parent = nullptr);
    virtual ~TreeNode();

    NodeType nodeType() const;
    void setNodeType(NodeType newNodeType);

    QString name() const;
    void setName(const QString& newName);

    QString uuid() const;
    void setUuid(const QString& newUuid);

    void addNode(TreeNode* node);
    void insertNode(qsizetype index, TreeNode* node);
    void removeNode(TreeNode* node);
    void removeNode(qsizetype index);
    void softRemoveNode(qsizetype index);
    void removeNodes();
    void moveNode(qsizetype from, qsizetype to);
    virtual void setParent(TreeNode* node);
    bool isHasChild(TreeNode* child) const noexcept;
    QList<TreeNode*> nodes() noexcept;
    virtual TreeNode* parent() const noexcept;

signals:
    void nodeTypeChanged();
    void nameChanged();
    void uuidChanged();

private:
    NodeType _nodeType;
    QString _name;
    QString _uuid;
    QList<TreeNode*> _nodes;
    TreeNode* _parent;
};

#endif // TREE_NODE_H
