#include "workspace.h"
#include <QDebug>

Workspace::Workspace(TreeNode* parent)
    : TreeNode(parent)
{
    QStringList cfgLocation = QStandardPaths::standardLocations(QStandardPaths::ConfigLocation);
    _workspacesPath = cfgLocation.first() + "/rester/workspaces/";
}

QJsonObject Workspace::toJson()
{
    QJsonObject json = {
        { "uuid", uuid() },
        { "name", name() },
        { "last_usage_at", _lastUsageAt },
        { "variables", QJsonObject::fromVariantMap(_variables) },
        { "pins", QJsonArray::fromStringList(_pins) }
    };
    QJsonArray items;

    for (TreeNode* node : nodes()) {
        items << std::move(serializeNode(node));
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

QList<TreeNode*> Workspace::getAllFolders(TreeNode* node)
{
    QList<TreeNode*> nodes;
    QList<TreeNode*> childs;

    if (node == nullptr) {
        childs = this->nodes();
    } else {
        nodes << node->nodes();
    }

    if (childs.isEmpty()) {
        return nodes;
    }

    for (TreeNode* child : childs) {
        if (child->nodeType() == NodeType::FolderNode) {
            auto childNodes = getAllFolders(child);
            nodes << childNodes;
        }
    }

    return nodes;
}

TreeNode* Workspace::getByUuid(QString uuid) noexcept
{
    QList<TreeNode*> childs = nodes();

    for (TreeNode* child : childs) {
        if (child->nodeType() != NodeType::FolderNode) {
            continue;
        }

        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            if (child->nodeType() != NodeType::FolderNode) {
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
        // if (child->nodeType() != NodeType::QueryNode) {
        //     continue;
        // }

        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            // if (child->nodeType() != NodeType::FolderNode) {
            //     continue;
            // }

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

    switch (json.value("node_type").toInt(-1)) {
    case NodeType::QueryNode: {
        auto qry = new Query(parent);
        qry->fromJson(json);
        parent->addNode(qry);
    } break;
    case NodeType::FolderNode:
        buildFolder(json, parent);
        break;
    }
}

void Workspace::buildFolder(const QJsonObject& json, TreeNode* parent)
{
    auto folder = new Folder(parent);
    folder->setName(json.value("name").toString("folder"));
    folder->setUuid(json.value("uuid").toString(Util::uuid()));
    folder->setNodeType(NodeType::FolderNode);
    folder->setIsExpanded(json.value("is_expanded").toBool());
    parent->addNode(folder);

    if (json.contains("queries")) {
        QJsonArray queries = json.value("queries").toArray();

        for (QJsonValueRef&& item : queries) {
            auto qry = new Query(folder);
            qry->fromJson(item.toObject());
            folder->addNode(qry);
        }
    }

    if (json.contains("folders")) {
        QJsonArray folders = json.value("folders").toArray();

        for (QJsonValueRef&& child : folders) {
            buildTree(child.toObject(), folder);
        }
    }
}

QJsonObject Workspace::buildJsonTree(QObject* node) const
{
    auto childNode = static_cast<TreeNode*>(node);
    QJsonObject childJson = serializeNode(childNode);

    return childJson;
}

QJsonObject Workspace::serializeNode(TreeNode* node) const
{
    QJsonObject json;

    switch (node->nodeType()) {
    case NodeType::FolderNode: {
        auto folder = static_cast<Folder*>(node);
        json = serializeFolder(folder);
    } break;
    case NodeType::QueryNode: {
        auto query = static_cast<Query*>(node);
        json = serializeQuery(query);
    } break;
    default:
        return {};
    }

    return json;
}

QJsonObject Workspace::serializeFolder(Folder* node) const
{
    if (node == nullptr) {
        return {};
    }

    QJsonObject json = {
        { "uuid", node->uuid() },
        { "name", node->name() },
        { "node_type", node->nodeType() },
        { "is_expanded", node->isExpanded() },
    };

    for (TreeNode* child : node->nodes()) {
        if (child == nullptr) {
            continue;
        }

        QJsonObject childJson = serializeNode(child);
        QJsonArray arr;

        if (child->nodeType() == NodeType::FolderNode) {
            if (json.contains("folders")) {
                arr = json["folders"].toArray();
            }

            arr.append(childJson);
            json["folders"] = arr;
        }

        if (child->nodeType() == NodeType::QueryNode) {
            if (json.contains("queries")) {
                arr = json["queries"].toArray();
            }

            arr << childJson;
            json["queries"] = arr;
        }
    }

    return json;
}

QJsonObject Workspace::serializeQuery(Query* node) const
{
    if (node == nullptr) {
        return {};
    }

    return node->toJson();
}

QJsonObject Workspace::serializeAnswer(HttpAnswer* node) const
{
    if (node == nullptr) {
        return {};
    }

    return node->toJson();
}

TreeNode* Workspace::getByUuid(QString uuid, TreeNode* node) const noexcept
{
    if (node == nullptr) {
        return nullptr;
    }

    QList<TreeNode*> childs = node->nodes();

    for (TreeNode* child : childs) {
        if (child->nodeType() != NodeType::FolderNode) {
            continue;
        }

        if (child->uuid() == uuid) {
            return child;
        }

        if (!child->nodes().isEmpty()) {
            if (child->nodeType() != NodeType::FolderNode) {
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

InsomniaResource Workspace::toInsomniaResource() const noexcept
{
    qint64 millis = QDateTime::currentMSecsSinceEpoch();
    InsomniaResource resource;
    resource.id = InsomniaWorkspacePrefix + Util::uuid();
    resource.modified = millis;
    resource.created = millis;
    resource.name = name();

    return resource;
}

Workspace* Workspace::getByQuery(TreeNode* query)
{
    auto parent = static_cast<TreeNode*>(query->parent());

    if (parent == nullptr) {
        return static_cast<Workspace*>(query);
    }

    if (parent->parent() != nullptr) {
        auto node = static_cast<TreeNode*>(parent->parent());
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
    QString path = _workspacesPath + getFileName();
    QJsonObject json = Util::getJsonFromFile(path);
    auto vars = json["variables"].toObject().toVariantMap();

    QStringList names;
    names.reserve(vars.size() - 1);
    QStringList keys = vars.keys();

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
    _pins.removeIf([&](const QString& str) {
        return str == pin;
    });

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
