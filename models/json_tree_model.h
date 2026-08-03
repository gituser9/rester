#ifndef JSON_TREE_MODEL_H
#define JSON_TREE_MODEL_H

#include <QAbstractListModel>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>
#include <qqmlintegration.h>

struct JsonNode {
    QString key;
    QJsonValue value;
    int depth = 0;
    bool isContainer = false;
    bool isArray = false;
    bool isObject = false;
    bool expanded = true;
    bool isClosing = false;
    QString closingText;
    int parentIndex = -1;
};

class JsonTreeModel : public QAbstractListModel
{
    Q_OBJECT
    // QML_ELEMENT

    Q_PROPERTY(QString jsonText READ jsonText WRITE setJsonText NOTIFY jsonTextChanged)
    Q_PROPERTY(QString filterText READ filterText WRITE setFilterText NOTIFY filterTextChanged)

public:
    explicit JsonTreeModel(QObject* parent = nullptr);

    // Basic functionality:
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void toggleExpand(int visibleIndex);

    QString jsonText() const;
    void setJsonText(const QString& text);

    QString filterText() const;
    void setFilterText(const QString& filter);

signals:
    void jsonTextChanged();
    void filterTextChanged();

private:
    enum class NodeRoles {
        KeyRole = Qt::UserRole + 1,
        ValueRole,
        DepthRole,
        IsContainerRole,
        IsArrayRole,
        IsObjectRole,
        ExpandedRole,
        IsClosingRole,
        DisplayValueRole
    };

    void rebuildTree();
    void parseValue(const QString& key, const QJsonValue& val, int depth, int parentIdx);
    void updateVisibleNodes();
    bool nodeMatchesFilter(int rawIndex, const QString& query) const;
    bool isDescendantOf(int rawIndex, int parentRawIndex) const;

    QString _jsonText;
    QString _filterText;

    QVector<JsonNode> _rawNodes;      // Полное дерево
    QVector<int> _visibleNodeIndices; // Индексы узлов, видимых в данный момент
};

#endif // JSON_TREE_MODEL_H
