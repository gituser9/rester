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

void Folder::fromJson(const QJsonObject& json)
{
}

QJsonObject Folder::toJson()
{
    QJsonObject json = {
        {"uuid", uuid()},
        {"name", name()},
        {"node_type", static_cast<int>(RstEnums::NodeType::FolderNode)},
        {"is_expanded", _isExpanded},
    };

    for (TreeNode* child : nodes()) {
        if (child == nullptr) {
            continue;
        }

        QJsonObject childJson = child->toJson();
        QJsonArray arr;

        if (child->nodeType() == RstEnums::NodeType::FolderNode) {
            if (json.contains("folders")) {
                arr = json["folders"].toArray();
            }

            arr.append(childJson);
            json["folders"] = arr;
        }
        else {
            if (json.contains("queries")) {
                arr = json["queries"].toArray();
            }

            arr << childJson;
            json["queries"] = arr;
        }
    }

    return json;
}
