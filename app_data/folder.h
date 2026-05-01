#ifndef FOLDER_H
#define FOLDER_H

#include <QDateTime>
#include <QJsonArray>
#include <QJsonObject>
#include <QUuid>

#include "tree_node.h"

class Folder : public TreeNode
{
    Q_OBJECT

    Q_PROPERTY(bool isExpanded READ isExpanded WRITE setIsExpanded NOTIFY isExpandedChanged)

public:
    explicit Folder(TreeNode* parent = nullptr);
    virtual ~Folder() = default;

    bool isExpanded() const;
    void setIsExpanded(bool newIsExpanded);

signals:
    void isExpandedChanged();

private:
    bool _isExpanded;
};

#endif // FOLDER_H
