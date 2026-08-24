#include "xml_tree_model.h"

XmlTreeModel::XmlTreeModel(QObject* parent) : QAbstractListModel(parent)
{
    _names.insert({
        {static_cast<int>(NodeRoles::TagNameRole), "nodeTagName"},
        {static_cast<int>(NodeRoles::DepthRole), "nodeDepth"},
        {static_cast<int>(NodeRoles::IsContainerRole), "nodeIsContainer"},
        {static_cast<int>(NodeRoles::IsClosingRole), "nodeIsClosing"},
        {static_cast<int>(NodeRoles::ExpandedRole), "nodeExpanded"},
        {static_cast<int>(NodeRoles::RichTextRole), "nodeRichText"} //
    });
}

int XmlTreeModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return _visibleNodeIndices.size();
}

QVariant XmlTreeModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= _visibleNodeIndices.size()) {
        return {};
    }

    int rawIdx = _visibleNodeIndices[index.row()];
    const auto& node = _rawNodes[rawIdx];
    auto nodeType = static_cast<NodeRoles>(role);

    switch (nodeType) {
    case NodeRoles::TagNameRole:
        return node.tagName;
    case NodeRoles::DepthRole:
        return node.depth;
    case NodeRoles::IsContainerRole:
        return node.isContainer;
    case NodeRoles::IsClosingRole:
        return node.isClosing;
    case NodeRoles::ExpandedRole:
        return node.expanded;
    case NodeRoles::RichTextRole:
        return formatNodeToHtml(node);
    default:
        return {};
    }
}

QHash<int, QByteArray> XmlTreeModel::roleNames() const
{
    return _names;
}

void XmlTreeModel::setXmlText(const QString& text)
{
    if (_xmlText == text) {
        return;
    }

    _xmlText = text;

    emit xmlTextChanged();
    parseXml();
    updateVisibleNodes();
}

void XmlTreeModel::setFilterText(const QString& text)
{
    if (_filterText == text) {
        return;
    }

    _filterText = text;

    emit filterTextChanged();
    updateVisibleNodes();
}

void XmlTreeModel::parseXml()
{
    _rawNodes.clear();
    if (_xmlText.trimmed().isEmpty())
        return;

    QXmlStreamReader xml(_xmlText);
    QStack<int> parentStack;

    while (!xml.atEnd() && !xml.hasError()) {
        QXmlStreamReader::TokenType token = xml.readNext();

        if (token == QXmlStreamReader::StartElement) {
            XmlNode node;
            node.tagName = xml.name().toString();
            node.depth = parentStack.size();
            node.parentIndex = parentStack.isEmpty() ? -1 : parentStack.last();

            // Парсинг атрибутов
            QStringList attrList;
            for (const auto& attr : xml.attributes()) {
                attrList.append(QString("<font color=\"#795da3\">%1</font>=<font color=\"#032f62\">\"%2\"</font>")
                                    .arg(attr.name().toString().toHtmlEscaped(), attr.value().toString().toHtmlEscaped()));
            }
            node.attributesString = attrList.join(" ");

            int currentRawIdx = _rawNodes.size();
            _rawNodes.append(node);
            parentStack.append(currentRawIdx);
        }
        else if (token == QXmlStreamReader::Characters) {
            QString text = xml.text().toString().trimmed();
            if (!text.isEmpty() && !parentStack.isEmpty()) {
                int currentIdx = parentStack.last();
                if (!_rawNodes[currentIdx].textContent.isEmpty()) {
                    _rawNodes[currentIdx].textContent += " ";
                }
                _rawNodes[currentIdx].textContent += text;
            }
        }
        else if (token == QXmlStreamReader::EndElement) {
            if (parentStack.isEmpty())
                continue;

            int startIdx = parentStack.pop();
            XmlNode& startNode = _rawNodes[startIdx];

            bool hasChildren = (_rawNodes.size() - 1 > startIdx);
            startNode.isContainer = hasChildren;

            if (hasChildren) {
                XmlNode closingNode;
                closingNode.tagName = startNode.tagName;
                closingNode.depth = startNode.depth;
                closingNode.parentIndex = startNode.parentIndex;
                closingNode.isClosing = true;
                _rawNodes.append(closingNode);
            }
            else if (startNode.textContent.isEmpty() && startNode.attributesString.isEmpty()) {
                startNode.isSelfClosing = true;
            }
        }
    }
}

QString XmlTreeModel::formatNodeToHtml(const XmlNode& node) const
{
    if (node.isClosing) {
        return QString("&lt;/<font color=\"#22863a\"><b>%1</b></font>&gt;").arg(node.tagName.toHtmlEscaped());
    }

    QString html = QString("&lt;<font color=\"#22863a\"><b>%1</b></font>").arg(node.tagName.toHtmlEscaped());

    if (!node.attributesString.isEmpty()) {
        html += " " + node.attributesString;
    }

    if (!node.isContainer) {
        if (!node.textContent.isEmpty()) {
            html += QString("&gt;<font color=\"#24292e\">%1</font>&lt;/<font color=\"#22863a\"><b>%2</b></font>&gt;")
                        .arg(node.textContent.toHtmlEscaped(), node.tagName.toHtmlEscaped());
        }
        else if (node.isSelfClosing) {
            html += " /&gt;";
        }
        else {
            html += QString("&gt;&lt;/<font color=\"#22863a\"><b>%1</b></font>&gt;").arg(node.tagName.toHtmlEscaped());
        }
    }
    else {
        html += "&gt;";
    }

    return html;
}

bool XmlTreeModel::nodeMatchesFilter(int rawIndex, const QString& filter) const
{
    const auto& node = _rawNodes[rawIndex];
    return node.tagName.contains(filter, Qt::CaseInsensitive) ||
           node.attributesString.contains(filter, Qt::CaseInsensitive) ||
           node.textContent.contains(filter, Qt::CaseInsensitive);
}

bool XmlTreeModel::isDescendantOf(int rawIndex, int parentRawIndex) const
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

void XmlTreeModel::toggleExpand(int visibleIndex)
{
    if (visibleIndex < 0 || visibleIndex >= _visibleNodeIndices.size()) {
        return;
    }

    int rawIdx = _visibleNodeIndices[visibleIndex];
    bool willExpand = !_rawNodes[rawIdx].expanded;
    _rawNodes[rawIdx].expanded = willExpand;

    if (!willExpand) {
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
        QVector<int> toInsert;

        for (int i = rawIdx + 1; i < _rawNodes.size(); ++i) {
            if (!isDescendantOf(i, rawIdx)) {
                break;
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

    QModelIndex itemIndex = index(visibleIndex);
    int expandedRole = static_cast<int>(NodeRoles::ExpandedRole);
    int textRole = static_cast<int>(NodeRoles::RichTextRole);

    emit dataChanged(itemIndex, itemIndex, {expandedRole, textRole});
}

void XmlTreeModel::updateVisibleNodes()
{
    beginResetModel();
    _visibleNodeIndices.clear();

    QString query = _filterText.trimmed().toLower();
    bool isFiltering = !query.isEmpty();

    QVector<bool> keepInFilter(_rawNodes.size(), false);

    if (isFiltering) {
        for (int i = 0; i < _rawNodes.size(); ++i) {
            if (!_rawNodes[i].isClosing && nodeMatchesFilter(i, query)) {
                keepInFilter[i] = true;
                int pIdx = _rawNodes[i].parentIndex;

                while (pIdx != -1) {
                    keepInFilter[pIdx] = true;
                    _rawNodes[pIdx].expanded = true;
                    pIdx = _rawNodes[pIdx].parentIndex;
                }
            }
        }

        for (int i = 0; i < _rawNodes.size(); ++i) {
            if (_rawNodes[i].isClosing) {
                int pIdx = _rawNodes[i].parentIndex;

                if (pIdx != -1 && keepInFilter[pIdx]) {
                    keepInFilter[i] = true;
                }
            }
        }
    }

    for (int i = 0; i < _rawNodes.size(); ++i) {
        if (isFiltering && !keepInFilter[i]) {
            continue;
        }

        bool parentsExpanded = true;
        int pIdx = _rawNodes[i].parentIndex;

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
