#include "routesmodel.h"

using namespace std;

RoutesModel::RoutesModel(QObject* parent) : QAbstractItemModel(parent)
{
    _names = QAbstractItemModel::roleNames();
    _names.insert({
        {NameRole, "nodeName"},
        {NodeTypeRole, "nodeType"},
        {QueryTypeRole, "nodeQueryType"},
        {FolderExpandedRole, "isFolderExpanded"},
        {UuidRole, "nodeUuid"},
        {ParentUuidRole, "parentUuid"},
    });
}

RoutesModel::~RoutesModel()
{
}

QModelIndex RoutesModel::index(int row, int column, const QModelIndex& parent) const
{
    if (!hasIndex(row, column, parent)) {
        return {};
    }

    TreeNode* parentNode = getItem(parent);

    if (parentNode->nodes().empty()) {
        return {};
    }

    TreeNode* node = parentNode->nodes().at(row);

    if (node != nullptr) {
        return createIndex(row, column, node);
    }
    else {
        return {};
    }
}

QModelIndex RoutesModel::parent(const QModelIndex& index) const
{
    if (!index.isValid()) {
        return {};
    }

    TreeNode* node = getItem(index);
    TreeNode* parentNode = node->parent();

    if (parentNode == nullptr || parentNode == _currentWorkspace.get()) {
        return {};
    }

    TreeNode* grandParentNode = parentNode->parent();
    if (grandParentNode == nullptr) {
        return {};
    }

    qsizetype row = grandParentNode->nodes().indexOf(parentNode);
    if (row == -1) {
        return {};
    }

    return createIndex(row, 0, parentNode);
}

int RoutesModel::rowCount(const QModelIndex& parent) const
{
    if (_currentWorkspace == nullptr) {
        return 0;
    }

    TreeNode* parentItem = getItem(parent);

    if (!parentItem) {
        return 0;
    }

    return parentItem->nodes().size();
}

int RoutesModel::columnCount(const QModelIndex& parent) const
{
    Q_UNUSED(parent)
    return 1;
}

Q_INVOKABLE bool RoutesModel::hasChildren(const QModelIndex& parent) const
{
    TreeNode* parentNode = getItem(parent);

    return parentNode == nullptr ? false : !parentNode->nodes().isEmpty();
}

QVariant RoutesModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    TreeNode* item = getItem(index);

    switch (role) {
    case NameRole:
        return item->name();
    case NodeTypeRole:
        return item->nodeType();
    case QueryTypeRole:
        return getQueryTypeFromNode(item);
    case FolderExpandedRole:
        return getExpandedFromNode(item);
    case UuidRole:
        return item->uuid();
    case ParentUuidRole: {
        auto parentNode = static_cast<TreeNode*>(item->parent());
        return parentNode->uuid();
    } break;
    default:
        break;
    }

    return {};
}

QHash<int, QByteArray> RoutesModel::roleNames() const
{
    return _names;
}

bool RoutesModel::removeRows(int row, int count, const QModelIndex& parent)
{
    TreeNode* parentNode = getItem(parent);

    if (parentNode == nullptr || count <= 0) {
        qDebug() << "EXIT: parent null or count <= 0";
        return false;
    }

    if (row < 0 || row >= parentNode->nodes().size() || (row + count) > parentNode->nodes().size()) {
        return false;
    }

    TreeNode* child = parentNode->nodes().at(row);

    if (child == nullptr) {
        return false;
    }

    QString uuid = child->uuid();

    beginRemoveRows(parent, row, row + count - 1);
    // beginResetModel();
    parentNode->removeNode(row);
    // endResetModel();
    endRemoveRows();

    emit treeChanged(_currentWorkspace);
    emit queryRemoved(uuid);

    return true;
}

bool RoutesModel::moveRows(const QModelIndex& sourceParent, int sourceRow, int count, const QModelIndex& destinationParent, int destinationChild)
{
    if (sourceParent == destinationParent && sourceRow == destinationChild) {
        return false;
    }

    TreeNode* sourceParentNode = getItem(sourceParent);
    TreeNode* destinationParentNode = getItem(destinationParent);

    if (!sourceParentNode || !destinationParentNode) {
        return false;
    }

    if (sourceRow < 0 || sourceRow >= sourceParentNode->nodes().size()) {
        return false;
    }

    TreeNode* movingNode = sourceParentNode->nodes().at(sourceRow);

    if (destinationParentNode->nodeType() == NodeType::QueryNode) {
        auto destParentNode = destinationParentNode->parent();

        if (!destParentNode) {
            return false;
        }

        destinationChild = destParentNode->nodes().indexOf(destinationParentNode);
        destinationParentNode = destParentNode;
    }

    int destRow = destinationChild;

    if (sourceParent == destinationParent && destinationChild > sourceRow) {
        destRow = destinationChild + 1;
    }

    if (!beginMoveRows(sourceParent, sourceRow, sourceRow + count - 1, destinationParent, destRow)) {
        return false;
    }

    if (sourceParentNode == destinationParentNode) {
        sourceParentNode->moveNode(sourceRow, destinationChild);
    }
    else {
        sourceParentNode->softRemoveNode(sourceRow);

        if (destinationChild < 0 || destinationChild > destinationParentNode->nodes().count()) {
            destinationParentNode->addNode(movingNode);
        }
        else {
            destinationParentNode->insertNode(destinationChild, movingNode);
        }
    }

    endMoveRows();
    emit treeChanged(_currentWorkspace);

    return true;
}

bool RoutesModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid()) {
        return false;
    }

    TreeNode* node = getItem(index);

    switch (node->nodeType()) {
    case NodeType::QueryNode:
        updateQuery(index, value, role);
        break;
    case NodeType::FolderNode:
        updateFolder(index, value, role);
        break;
    default:
        return false;
    }

    emit dataChanged(index, index, {role});

    return true;
}

bool RoutesModel::canFetchMore(const QModelIndex& parent) const
{
    TreeNode* node = getItem(parent);

    return !node->nodes().isEmpty();
}

Qt::ItemFlags RoutesModel::flags(const QModelIndex& index) const
{
    if (!index.isValid()) {
        return Qt::ItemIsEditable;
    }

    return QAbstractItemModel::flags(index) | Qt::ItemIsEditable;
}

void RoutesModel::addFolder(QString name, const QModelIndex& parentIdx)
{
    TreeNode* parentNode = getItem(parentIdx);
    int row = parentNode->nodes().count();

    beginInsertRows(parentIdx, row, row);

    auto newFolder = new Folder(parentNode);
    newFolder->setUuid(Util::uuid());
    newFolder->setName(name);
    newFolder->setIsExpanded(true);
    newFolder->setNodeType(NodeType::FolderNode);
    parentNode->addNode(newFolder);

    endInsertRows();

    emit treeChanged(_currentWorkspace);
}

void RoutesModel::addQuery(QString name, const QModelIndex& parentIdx)
{
    TreeNode* parentNode = getItem(parentIdx);
    int row = parentNode->nodes().count();

    beginInsertRows(parentIdx, row, row);

    auto newQuery = new Query(parentNode);
    newQuery->setNodeType(NodeType::QueryNode);
    newQuery->setUuid(Util::uuid());
    newQuery->setName(name);
    newQuery->setQueryType(QueryType::GET);
    newQuery->setBodyType(BodyType::NONE);
    parentNode->addNode(newQuery);

    endInsertRows();

    emit treeChanged(_currentWorkspace);
}

void RoutesModel::addQuery(QString name, QString type, const QModelIndex& parentIdx)
{
    TreeNode* parentNode = getItem(parentIdx);
    int row = parentNode->nodes().count();
    QueryType queryType = Util::getQueryType(type);

    beginInsertRows(parentIdx, row, row);

    if (queryType == QueryType::GRPC) {
        auto newQuery = new GrpcQuery(parentNode);
        newQuery->setNodeType(NodeType::GrpcQueryNode);
        newQuery->setUuid(Util::uuid());
        newQuery->setName(name);
        parentNode->addNode(newQuery);
    }
    else {
        auto newQuery = new Query(parentNode);
        newQuery->setNodeType(NodeType::QueryNode);
        newQuery->setUuid(Util::uuid());
        newQuery->setName(name);
        newQuery->setQueryType(QueryType::GET);
        newQuery->setBodyType(BodyType::NONE);
        newQuery->setQueryType(queryType);
        parentNode->addNode(newQuery);
    }

    endInsertRows();

    emit treeChanged(_currentWorkspace);
}

void RoutesModel::updateFolder(const QModelIndex& index, const QVariant& value, int role)
{
    TreeNode* node = getItem(index);
    QString data = value.toString();

    if (role == RoleType::NameRole && node->name() != data) {
        node->setName(data);

        emit treeChanged(_currentWorkspace);
    }

    if (role == RoleType::ParentUuidRole) {
        TreeNode* parent = node->parent();

        if (parent->uuid() != data) {
            TreeNode* newParentNode = _currentWorkspace->getByUuid(data);

            if (newParentNode != nullptr) {
                node->setParent(newParentNode);
            }
            else {
                node->setParent(_currentWorkspace.get());
            }

            emit treeChanged(_currentWorkspace);
        }
    }
}

void RoutesModel::toggleFolderExpanded(const QModelIndex& idx)
{
    if (!idx.isValid()) {
        return;
    }

    auto fldr = static_cast<Folder*>(idx.internalPointer());
    fldr->setIsExpanded(!fldr->isExpanded());

    emit dataChanged(idx, idx, {FolderExpandedRole});
    emit treeChanged(_currentWorkspace);
}

bool RoutesModel::isFolderExpanded(const QModelIndex& idx) const
{
    if (!idx.isValid()) {
        return false;
    }

    TreeNode* node = getItem(idx);

    return getExpandedFromNode(node);
}

void RoutesModel::updateQuery(const QModelIndex& index, const QVariant& value, int role)
{
    QString qryData = value.toString();
    TreeNode* node = getItem(index);

    if (!node) {
        return;
    }

    node->setName(qryData);

    emit treeChanged(_currentWorkspace);
}

void RoutesModel::setCurrentQuery(const QModelIndex& idx)
{
    TreeNode* node = getItem(idx);

    if (node && node->nodeType() == NodeType::QueryNode) {
        auto qry = static_cast<Query*>(node);

        emit setQuery(qry);
    }

    if (node && node->nodeType() == NodeType::GrpcQueryNode) {
        auto qry = static_cast<GrpcQuery*>(node);

        emit setGrpcQuery(qry);
    }
}

TreeNode* RoutesModel::getItem(const QModelIndex& idx) const noexcept
{
    if (!idx.isValid()) {
        return _currentWorkspace.get();
    }

    auto item = static_cast<TreeNode*>(idx.internalPointer());

    if (item) {
        return item;
    }

    return _currentWorkspace.get();
}

void RoutesModel::loadTree(shared_ptr<Workspace> workspace) noexcept
{
    beginResetModel();
    _currentWorkspace = workspace;
    endResetModel();

    emit treeLoaded();
}

QString RoutesModel::getQueryTypeFromNode(TreeNode* node) const noexcept
{
    if (node->nodeType() == NodeType::FolderNode) {
        return "";
    }

    if (node->nodeType() == NodeType::QueryNode) {
        auto qry = static_cast<Query*>(node);

        if (qry == nullptr) {
            return Util::getQueryTypeString(QueryType::GET);
        }

        return Util::getQueryTypeString(qry->queryType());
    }

    if (node->nodeType() == NodeType::GrpcQueryNode) {
        return Util::getQueryTypeString(QueryType::GRPC);
    }

    return Util::getQueryTypeString(QueryType::GET);
}

bool RoutesModel::getExpandedFromNode(TreeNode* node) const noexcept
{
    const Folder* fldr = static_cast<Folder*>(node);

    if (fldr == nullptr) {
        return false;
    }

    return fldr->isExpanded();
}

QString RoutesModel::copyAsCurl(const QModelIndex& idx) const
{
    auto qry = static_cast<Query*>(idx.internalPointer());

    if (qry == nullptr || qry->uuid() == "") {
        return "";
    }

    auto curlParser = std::make_unique<CurlParser>();

    return curlParser->generateCurl(qry);
}

void RoutesModel::downloadBigAnswer(QString dirPath, Query const* qry) const noexcept
{
    QString fileName = qry->fileNameForAnswer();
    QFile answerFile(dirPath + "/" + fileName);

    if (!answerFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        // signal
        return;
    }

    QTextStream outStream(&answerFile);
    outStream << qry->lastAnswer()->body();

    answerFile.close();
}

void RoutesModel::importFromHar(const QModelIndex& parentIdx, const QString& filePath) noexcept
{
    TreeNode* parentNode = getItem(parentIdx);
    auto importer = std::make_unique<Importer>();
    auto ws = importer->importWorkspace(filePath, ImportType::Har);

    //    beginInsertRows(parentIdx, row, row);

    if (!ws) {
        emit error("Import from HAR error");
        return;
    }

    beginResetModel();

    for (TreeNode* qry : ws->nodes()) {
        parentNode->addNode(qry);
    }

    //    endInsertRows();
    endResetModel();

    emit treeChanged(_currentWorkspace);
}
