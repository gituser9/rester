#ifndef FOLDER_H
#define FOLDER_H

#include <QDateTime>
#include <QJsonArray>
#include <QJsonObject>
#include <QUuid>

#include "insomnia/insomnia.h"
#include "postman/postman.h"
#include "tree_node.h"

class Folder : public TreeNode {
    Q_OBJECT

    Q_PROPERTY(bool isExpanded READ isExpanded WRITE setIsExpanded NOTIFY isExpandedChanged)

public:
    explicit Folder(TreeNode* parent = nullptr);
    virtual ~Folder() = default;

    bool isExpanded() const;
    void setIsExpanded(bool newIsExpanded);
    QList<InsomniaResource> toInsomniaResource(const QString& parentId, Folder* fld) noexcept;
    QList<PostmanItem> toPostmanItem(Folder* fld) noexcept;

signals:
    void isExpandedChanged();

private:
    bool _isExpanded;
};

#endif // FOLDER_H
