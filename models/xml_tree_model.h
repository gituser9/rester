#ifndef XML_TREE_MODEL_H
#define XML_TREE_MODEL_H

#include <QAbstractListModel>
#include <QXmlStreamReader>
#include <QVector>
#include <QStack>

struct XmlNode {
    QString tagName;
    QString attributesString;
    QString textContent;
    int depth = 0;
    int parentIndex = -1;
    bool isContainer = false;
    bool isClosing = false;
    bool isSelfClosing = false;
    bool expanded = true;
};

class XmlTreeModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString xmlText READ xmlText WRITE setXmlText NOTIFY xmlTextChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)

public:
    explicit XmlTreeModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString xmlText() const
    {
        return _xmlText;
    }
    void setXmlText(const QString& text);

    QString filterText() const
    {
        return _filterText;
    }
    void setFilterText(const QString& text);

    Q_INVOKABLE void toggleExpand(int visibleIndex);

signals:
    void xmlTextChanged();
    void filterTextChanged();

private:
    enum class NodeRoles {
        TagNameRole = Qt::UserRole + 1,
        DepthRole,
        IsContainerRole,
        IsClosingRole,
        ExpandedRole,
        RichTextRole
    };

    void parseXml();
    void updateVisibleNodes();
    bool nodeMatchesFilter(int rawIndex, const QString& filter) const;
    bool isDescendantOf(int rawIndex, int parentRawIndex) const;
    QString formatNodeToHtml(const XmlNode& node) const;

    QString _xmlText;
    QString _filterText;
    QVector<XmlNode> _rawNodes;
    QVector<int> _visibleNodeIndices;
    QHash<int, QByteArray> _names;
};

#endif // XML_TREE_MODEL_H
