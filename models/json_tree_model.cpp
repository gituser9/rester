#include "json_tree_model.h"

JsonTreeModel::JsonTreeModel(QObject* parent) : QAbstractListModel(parent)
{
    _names.insert({
        {static_cast<int>(NodeRoles::KeyRole), "nodeKey"},
        {static_cast<int>(NodeRoles::DepthRole), "nodeDepth"},
        {static_cast<int>(NodeRoles::IsContainerRole), "nodeIsContainer"},
        {static_cast<int>(NodeRoles::IsArrayRole), "nodeIsArray"},
        {static_cast<int>(NodeRoles::IsObjectRole), "nodeIsObject"},
        {static_cast<int>(NodeRoles::ExpandedRole), "nodeExpanded"},
        {static_cast<int>(NodeRoles::IsClosingRole), "nodeIsClosing"},
        {static_cast<int>(NodeRoles::DisplayValueRole), "nodeDisplayValue"} //
    });
}

int JsonTreeModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return _visibleNodeIndices.size();
}

QVariant JsonTreeModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= _visibleNodeIndices.size()) {
        return {};
    }

    int rawIdx = _visibleNodeIndices[index.row()];
    const auto& node = _rawNodes[rawIdx];
    auto nodeRole = static_cast<NodeRoles>(role);

    switch (nodeRole) {
    case NodeRoles::KeyRole:
        return node.key;
    case NodeRoles::DepthRole:
        return node.depth;
    case NodeRoles::IsContainerRole:
        return node.isContainer;
    case NodeRoles::IsArrayRole:
        return node.isArray;
    case NodeRoles::IsObjectRole:
        return node.isObject;
    case NodeRoles::ExpandedRole:
        return node.expanded;
    case NodeRoles::IsClosingRole:
        return node.isClosing;
    case NodeRoles::DisplayValueRole: {
        if (node.isClosing) {
            return node.closingText;
        }
        if (node.isObject) {
            if (node.expanded) {
                return "{";
            }
            int count = node.value.toObject().size();
            return QString("{ Object(%1) }").arg(count);
        }
        if (node.isArray) {
            if (node.expanded) {
                return "[";
            }
            int count = node.value.toArray().size();
            return QString("[ Array(%1) ]").arg(count);
        }
        if (node.value.isNull()) {
            return "null";
        }
        if (node.value.isString()) {
            return QString("\"%1\"").arg(node.value.toString());
        }
        if (node.value.isDouble()) {
            return QString::number(node.value.toDouble());
        }
        if (node.value.isBool()) {
            return node.value.toBool() ? "true" : "false";
        }

        return QString();
    }
    default:
        return {};
    }
}

QHash<int, QByteArray> JsonTreeModel::roleNames() const
{
    return _names;
}

void JsonTreeModel::setJsonText(const QString& text)
{
    if (_jsonText == text) {
        return;
    }

    _jsonText = text;

    emit jsonTextChanged();

    rebuildTree();
}

QString JsonTreeModel::filterText() const
{
    return _filterText;
}

void JsonTreeModel::setFilterText(const QString& filter)
{
    if (_filterText == filter) {
        return;
    }

    _filterText = filter;

    emit filterTextChanged();

    updateVisibleNodes();
}

void JsonTreeModel::rebuildTree()
{
    beginResetModel();

    _rawNodes.clear();
    _visibleNodeIndices.clear();

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(_jsonText.toUtf8(), &err);

    if (doc.isObject()) {
        parseValue("", doc.object(), 0, -1);
    }
    else if (doc.isArray()) {
        parseValue("", doc.array(), 0, -1);
    }

    endResetModel();
    updateVisibleNodes();
}

void JsonTreeModel::parseValue(const QString& key, const QJsonValue& val, int depth, int parentIdx)
{
    int currentIdx = _rawNodes.size();
    JsonNode node;
    node.key = key;
    node.value = val;
    node.depth = depth;
    node.parentIndex = parentIdx;
    node.isObject = val.isObject();
    node.isArray = val.isArray();
    node.isContainer = node.isObject || node.isArray;
    node.isClosing = false;

    _rawNodes.append(node);

    if (val.isObject()) {
        QJsonObject obj = val.toObject();

        for (auto it = obj.begin(); it != obj.end(); ++it) {
            parseValue(it.key(), it.value(), depth + 1, currentIdx);
        }

        // Закрывающая скобка объекта на том же уровне глубины depth
        JsonNode closingNode;
        closingNode.depth = depth;
        closingNode.parentIndex = currentIdx;
        closingNode.isClosing = true;
        closingNode.closingText = "}";
        _rawNodes.append(closingNode);
    }
    else if (val.isArray()) {
        QJsonArray arr = val.toArray();
        for (const QJsonValue& item : arr) {
            parseValue("", item, depth + 1, currentIdx);
        }
        // Закрывающая скобка массива на том же уровне глубины depth
        JsonNode closingNode;
        closingNode.depth = depth;
        closingNode.parentIndex = currentIdx;
        closingNode.isClosing = true;
        closingNode.closingText = "]";
        _rawNodes.append(closingNode);
    }
}

void JsonTreeModel::toggleExpand(int visibleIndex)
{
    if (visibleIndex < 0 || visibleIndex >= _visibleNodeIndices.size()) {
        return;
    }

    int rawIdx = _visibleNodeIndices[visibleIndex];
    bool willExpand = !_rawNodes[rawIdx].expanded;
    _rawNodes[rawIdx].expanded = willExpand;

    if (!willExpand) {
        // --- СВОРАЧИВАНИЕ ---
        // Считаем, сколько элементов ниже являются потомками текущего узла
        int removeCount = 0;

        for (int i = visibleIndex + 1; i < _visibleNodeIndices.size(); ++i) {
            if (isDescendantOf(_visibleNodeIndices[i], rawIdx)) {
                removeCount++;
            }
            else {
                break;
            }
        }

        if (removeCount > 0) {
            beginRemoveRows(QModelIndex(), visibleIndex + 1, visibleIndex + removeCount);
            _visibleNodeIndices.remove(visibleIndex + 1, removeCount);
            endRemoveRows();
        }
    }
    else {
        // --- РАЗВОРАЧИВАНИЕ ---
        // Собираем потомков, у которых все промежуточные предки развернуты
        QVector<int> toInsert;

        for (int i = rawIdx + 1; i < _rawNodes.size(); ++i) {
            if (!isDescendantOf(i, rawIdx)) {
                break; // Вышли за пределы поддерева
            }

            bool parentsExpanded = true;
            int pIdx = _rawNodes[i].parentIndex;

            while (pIdx != rawIdx && pIdx != -1) {
                if (!_rawNodes[pIdx].expanded) {
                    parentsExpanded = false;
                    break;
                }

                pIdx = _rawNodes[pIdx].parentIndex;
            }

            if (parentsExpanded) {
                toInsert.append(i);
            }
        }

        if (!toInsert.isEmpty()) {
            beginInsertRows(QModelIndex(), visibleIndex + 1, visibleIndex + toInsert.size());

            for (int i = 0; i < toInsert.size(); ++i) {
                _visibleNodeIndices.insert(visibleIndex + 1 + i, toInsert[i]);
            }

            endInsertRows();
        }
    }

    // Уведомляем QML, что у кликнутого элемента изменились роли.
    // Элемент НЕ уничтожается, и Behavior on rotation отработает идеальную анимацию!
    QModelIndex itemIndex = index(visibleIndex);
    int expandedRole = static_cast<int>(NodeRoles::ExpandedRole);
    int displayRole = static_cast<int>(NodeRoles::DisplayValueRole);
    emit dataChanged(itemIndex, itemIndex, {expandedRole, displayRole});
}

QString JsonTreeModel::jsonText() const
{
    return _jsonText;
}

void JsonTreeModel::updateVisibleNodes()
{
    beginResetModel();
    _visibleNodeIndices.clear();

    QString query = _filterText.trimmed().toLower();
    bool isFiltering = !query.isEmpty();

    QVector<bool> keepInFilter(_rawNodes.size(), false);

    // 1. Если включен поиск — находим совпадения и разворачиваем ветку предков
    if (isFiltering) {
        // Шаг A: Ищем совпадения и поднимаемся к корню дерева
        for (int i = 0; i < _rawNodes.size(); ++i) {
            if (!_rawNodes[i].isClosing && nodeMatchesFilter(i, query)) {
                keepInFilter[i] = true;

                // Проходимся вверх по всем родителям до самого верха
                int pIdx = _rawNodes[i].parentIndex;

                while (pIdx != -1) {
                    keepInFilter[pIdx] = true;
                    _rawNodes[pIdx].expanded = true; // Автораскрытие контейнера
                    pIdx = _rawNodes[pIdx].parentIndex;
                }
            }
        }

        // Шаг B: Помечаем закрывающие скобки для сохраненных контейнеров
        for (int i = 0; i < _rawNodes.size(); ++i) {
            if (_rawNodes[i].isClosing) {
                int pIdx = _rawNodes[i].parentIndex;

                if (pIdx != -1 && keepInFilter[pIdx]) {
                    keepInFilter[i] = true;
                }
            }
        }
    }

    // 2. Формируем итоговый список видимых элементов для QML ListView
    for (int i = 0; i < _rawNodes.size(); ++i) {
        const auto& node = _rawNodes[i];

        // Пропускаем узлы, которые не входят в путь поиска
        if (isFiltering && !keepInFilter[i]) {
            continue;
        }

        // Проверяем, что все предки текущего узла развернуты
        bool parentsExpanded = true;
        int pIdx = node.parentIndex;

        while (pIdx != -1) {
            if (!_rawNodes[pIdx].expanded) {
                parentsExpanded = false;
                break;
            }

            pIdx = _rawNodes[pIdx].parentIndex;
        }

        if (parentsExpanded) {
            _visibleNodeIndices.append(i);
        }
    }

    endResetModel();
}

bool JsonTreeModel::nodeMatchesFilter(int rawIndex, const QString& query) const
{
    const auto& node = _rawNodes[rawIndex];

    if (node.key.toLower().contains(query)) {
        return true;
    }

    if (node.value.isString() && node.value.toString().toLower().contains(query)) {
        return true;
    }

    return false;
}

bool JsonTreeModel::isDescendantOf(int rawIndex, int parentRawIndex) const
{
    int pIdx = _rawNodes[rawIndex].parentIndex;

    while (pIdx != -1) {
        if (pIdx == parentRawIndex) {
            return true;
        }

        pIdx = _rawNodes[pIdx].parentIndex;
    }

    return false;
}
