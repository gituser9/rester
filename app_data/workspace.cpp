#include "workspace.h"
#include <QDebug>

Workspace::Workspace(TreeNode* parent) : TreeNode(parent)
{
    QStringList cfgLocation = QStandardPaths::standardLocations(QStandardPaths::ConfigLocation);
    _workspacesPath = cfgLocation.first() + "/rester/workspaces/";
}

QJsonObject Workspace::toJson()
{
    QJsonObject json = {
        {"uuid", uuid()},
        {"name", name()},
        {"last_usage_at", _lastUsageAt},
        {"variables", QJsonObject::fromVariantMap(_variables)},
        {"pins", QJsonArray::fromStringList(_pins)} //
    };
    QJsonArray items;

    for (TreeNode* node : nodes()) {
        items << node->toJson();
    }

    json["items"] = items;

    return json;
}

void Workspace::fromJson(const QJsonObject& json)
{
    setName(json.value("name").toString("workspace"));
    setUuid(json.value("uuid").toString(Util::uuid()));
    setLastUsageAt(json.value("last_usage_at").toInteger());
    setVariables(json.value("variables").toObject().toVariantMap());

    auto pins = json.value("pins").toArray();
    _pins.reserve(pins.size());

    for (auto&& pin : pins) {
        _pins << pin.toString();
    }

    _env = _variables["env"].toString();

    emit envChanged();

    QJsonArray itemsArray = json.value("items").toArray();

    for (QJsonValueRef&& item : itemsArray) {
        buildTree(item.toObject(), this);
    }
}

void Workspace::fromJsonShort(const QJsonObject& json) noexcept
{
    setName(json.value("name").toString("workspace"));
    setUuid(json.value("uuid").toString(Util::uuid()));
    setLastUsageAt(json.value("last_usage_at").toInteger());
}

QString Workspace::getFileName() const
{
    QString nameForFile = name()
                              .replace(" ", "_")
                              .toLower()
                              .append("_")
                              .append(uuid())
                              .append(".json");

    return nameForFile;
}

void Workspace::createDefault()
{
    setName("Default Workspace");
    setUuid(Util::uuid());
    _lastUsageAt = 0;
}

TreeNode* Workspace::getByUuid(QString uuid) noexcept
{
    QList<TreeNode*> childs = nodes();

    for (TreeNode* child : childs) {
        if (child->nodeType() != RstEnums::NodeType::FolderNode) {
            continue;
        }

        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            if (child->nodeType() != RstEnums::NodeType::FolderNode) {
                continue;
            }

            TreeNode* node = getByUuid(uuid, child);

            if (node != nullptr) {
                return node;
            }
        }
    }

    return nullptr;
}

TreeNode* Workspace::getQueryByUuid(QString uuid) noexcept
{
    QList<TreeNode*> childs = nodes();

    for (TreeNode* child : childs) {
        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            TreeNode* node = getQueryByUuid(uuid, child);

            if (node != nullptr) {
                return node;
            }
        }
    }

    return nullptr;
}

void Workspace::buildTree(const QJsonObject& json, TreeNode* parent)
{
    if (json.empty()) {
        return;
    }

    int typeInt = json.value("node_type").toInt(-1);

    if (typeInt == -1) {
        return;
    }

    auto nodeType = static_cast<RstEnums::NodeType>(typeInt);
    TreeNode* newNode;

    switch (nodeType) {
    case RstEnums::NodeType::QueryNode:
        newNode = new Query(parent);
        break;
    case RstEnums::NodeType::GrpcQueryNode:
        newNode = new GrpcQuery(parent);
        break;
    case RstEnums::NodeType::GraphqlQueryNode:
        newNode = new GraphqlQuery(parent);
        break;
    case RstEnums::NodeType::FolderNode:
        buildFolder(json, parent);
        return;
    default:
        return;
    }

    newNode->fromJson(json);
    parent->addNode(newNode);
}

void Workspace::buildFolder(const QJsonObject& json, TreeNode* parent)
{
    auto folder = new Folder(parent);
    folder->setName(json.value("name").toString("folder"));
    folder->setUuid(json.value("uuid").toString(Util::uuid()));
    folder->setNodeType(RstEnums::NodeType::FolderNode);
    folder->setIsExpanded(json.value("is_expanded").toBool());
    parent->addNode(folder);

    if (json.contains("queries")) {
        QJsonArray queries = json.value("queries").toArray();

        for (QJsonValueRef&& item : queries) {
            auto obj = item.toObject();

            int typeInt = obj.value("node_type").toInt(-1);

            if (typeInt == -1) {
                continue; // TODO: emit error
            }

            auto typ = static_cast<RstEnums::NodeType>(typeInt);
            TreeNode* newNode;

            switch (typ) {
            case RstEnums::NodeType::QueryNode:
                newNode = new Query(parent);
                break;
            case RstEnums::NodeType::GrpcQueryNode:
                newNode = new GrpcQuery(parent);
                break;
            case RstEnums::NodeType::GraphqlQueryNode:
                newNode = new GraphqlQuery(parent);
                break;
            default:
                continue;
            }

            newNode->fromJson(item.toObject());
            folder->addNode(newNode);
        }
    }

    if (json.contains("folders")) {
        QJsonArray folders = json.value("folders").toArray();

        for (QJsonValueRef&& child : folders) {
            buildTree(child.toObject(), folder);
        }
    }
}

TreeNode* Workspace::getByUuid(QString uuid, TreeNode* node) const noexcept
{
    if (node == nullptr) {
        return nullptr;
    }

    QList<TreeNode*> childs = node->nodes();

    for (TreeNode* child : childs) {
        if (child->nodeType() != RstEnums::NodeType::FolderNode) {
            continue;
        }

        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            if (child->nodeType() != RstEnums::NodeType::FolderNode) {
                continue;
            }

            TreeNode* deepNode = getByUuid(uuid, child);

            if (deepNode != nullptr) {
                return deepNode;
            }
        }
    }

    return nullptr;
}

TreeNode* Workspace::getQueryByUuid(QString uuid, TreeNode* node) const noexcept
{
    if (node == nullptr) {
        return nullptr;
    }

    QList<TreeNode*> childs = node->nodes();

    for (TreeNode* child : childs) {
        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            TreeNode* deepNode = getQueryByUuid(uuid, child);

            if (deepNode != nullptr) {
                return deepNode;
            }
        }
    }

    return nullptr;
}

QString Workspace::getParentName(const TreeNode* node) const noexcept
{
    TreeNode* parent = node->parent();

    if (parent == this) {
        return {};
    }

    QString name = node->parent()->name() + " / ";

    if (parent != this) {
        name = getParentName(parent) + name;
    }

    return name;
}

qint64 Workspace::lastUsageAt() const
{
    return _lastUsageAt;
}

void Workspace::setLastUsageAt(qint64 newLastUsageAt)
{
    _lastUsageAt = newLastUsageAt;
    emit lastUsageAtChanged();
}

Workspace* Workspace::getByQuery(TreeNode* query)
{
    TreeNode* parent = query->parent();

    if (parent == nullptr) {
        return static_cast<Workspace*>(query);
    }

    if (parent->parent() != nullptr) {
        TreeNode* node = parent->parent();
        parent = getByQuery(node);
    }

    auto ws = static_cast<Workspace*>(parent);

    return ws;
}

QVariantMap Workspace::variables() const
{
    return _variables;
}

void Workspace::setVariables(const QVariantMap& newVariables)
{
    _variables = newVariables;

    emit variablesChanged();
}

void Workspace::reloadVariables() noexcept
{
    QString path = _workspacesPath + getFileName();
    QJsonObject json = Util::getJsonFromFile(path);
    _variables = json["variables"].toObject().toVariantMap();
}

QStringList Workspace::getEnvNames() const noexcept
{
    QStringList names;
    names.reserve(_variables.size() - 1);
    QStringList keys = _variables.keys();

    for (const QString& key : keys) {
        if (key == "env") {
            continue;
        }

        names << key;
    }

    return names;
}

void Workspace::setEnv(const QString& env) noexcept
{
    QString path = _workspacesPath + getFileName();
    QJsonObject json = Util::getJsonFromFile(path);

    QJsonObject vars = json["variables"].toObject();
    vars["env"] = env;

    setVariables(vars.toVariantMap());
    _env = env;

    emit envChanged();

    Util::writeJsonToFile(path, toJson());
}

QString Workspace::env() const
{
    return _env;
}

QStringList Workspace::pins() const
{
    return _pins;
}

void Workspace::setPins(const QStringList& newPins)
{
    if (_pins == newPins) {
        return;
    }

    _pins = newPins;

    emit pinsChanged();
}

void Workspace::addPin(const QString& newPin)
{
    _pins << newPin;

    emit pinsChanged();
}

void Workspace::removePin(const QString& pin)
{
    _pins.removeIf([&](const QString& str) { return str == pin; });

    emit pinsChanged();
}

void Workspace::removePin(int idx)
{
    _pins.removeAt(idx);

    emit pinsChanged();
}

QString Workspace::nodeFullPath(const QString& uuid) noexcept
{
    TreeNode* node = getQueryByUuid(uuid);

    if (node == nullptr) {
        return {};
    }

    return getParentName(node) + node->name();
}
