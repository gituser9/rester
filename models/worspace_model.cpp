#include "worspace_model.h"

using namespace std;

WorkspaceModel::WorkspaceModel(QObject* parent) : QAbstractListModel(parent)
{
    _names[NameRole] = "name";
    _names[UuidRole] = "uuid";
    _names[LastUsageRole] = "lastUsageAt";

    QStringList cfgLocation = QStandardPaths::standardLocations(QStandardPaths::ConfigLocation);
    _workspacesPath = cfgLocation.first() + "/rester/workspaces/";
}

WorkspaceModel::~WorkspaceModel()
{
}

int WorkspaceModel::rowCount(const QModelIndex& parent) const
{
    return _workspaces.count();
}

QVariant WorkspaceModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    if (index.row() < 0 || index.row() >= rowCount()) {
        return {};
    }

    auto item = _workspaces[index.row()];

    switch (role) {
    case NameRole:
        return item->name();
    case UuidRole:
        return item->uuid();
    case LastUsageRole:
        return item->lastUsageAt();
    default:
        break;
    }

    return {};
}

bool WorkspaceModel::removeRows(int row, int count, const QModelIndex& parent)
{
    shared_ptr<Workspace> ws = _workspaces.at(row);
    bool isRemoved = QFile::remove(_workspacesPath + ws->getFileName());

    if (!isRemoved) {
        return false;
    }

    beginRemoveRows(parent, row, row + count - 1);
    _workspaces.removeAt(row);
    endRemoveRows();

    return true;
}

bool WorkspaceModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid()) {
        return false;
    }

    shared_ptr<Workspace> ws = _workspaces.at(index.row());
    QString oldFileName = _workspacesPath + ws->getFileName();

    QString oldName = ws->name();
    ws->setName(value.toString());

    QString newFileName = _workspacesPath + ws->getFileName();
    bool isRenamed = QFile::rename(oldFileName, newFileName);

    if (!isRenamed) {
        ws->setName(oldName);
        return false;
    }

    emit dataChanged(index, index, {RoleNames::NameRole});
    emit wsUpdate(ws);

    return true;
}

Qt::ItemFlags WorkspaceModel::flags(const QModelIndex& index) const
{
    if (!index.isValid()) {
        return Qt::NoItemFlags;
    }

    return QAbstractListModel::flags(index) | Qt::ItemIsEditable;
}

QHash<int, QByteArray> WorkspaceModel::roleNames() const
{
    return _names;
}

void WorkspaceModel::loadWorkspaces()
{
    QDir workspacesDir(_workspacesPath);

    _workspaces.clear();

    QStringList dirs = workspacesDir.entryList();
    auto cap = dirs.size();
    _workspaces.reserve(cap);
    _allWorkspaces.reserve(cap);

    beginResetModel();

    for (const QString& fileName : dirs) {
        QString path = _workspacesPath + fileName;
        QJsonObject json = Util::getJsonFromFile(path);

        if (json.isEmpty()) {
            continue;
        }

        auto workspace = make_shared<Workspace>();
        workspace->fromJsonShort(json);

        _workspaces << workspace;
        _allWorkspaces << workspace;
    }

    std::sort(_workspaces.begin(), _workspaces.end(), [&](auto& left, auto& right) {
        return left->lastUsageAt() > right->lastUsageAt();
    });

    endResetModel();
}

void WorkspaceModel::exportCollection(const QString& folderPath, int index, int type) const
{
    shared_ptr<Workspace> ws = _workspaces.at(index);
    QString path = _workspacesPath + ws->getFileName();
    QJsonObject json = Util::getJsonFromFile(path);

    if (json.isEmpty()) {
        return;
    }

    auto workspace = QSharedPointer<Workspace>(new Workspace);
    workspace->fromJson(json);

    auto importer = unique_ptr<Importer>();
    auto enumValue = static_cast<ImportType>(type);

    importer->exportCollection(workspace, folderPath, enumValue);
}

void WorkspaceModel::clean() noexcept
{
    _workspaces.clear();
    _allWorkspaces.clear();
}

void WorkspaceModel::importFrom(const QString& filePath, ImportType type)
{
    auto importer = std::make_unique<Importer>();
    shared_ptr<Workspace> workspace = importer->importWorkspace(filePath, type);

    if (!workspace) {
        emit error("Parse files(s) error");

        return;
    }

    emit wsSave(workspace);

    beginResetModel();

    _workspaces.push_front(workspace);
    _allWorkspaces.push_front(workspace);

    endResetModel();
}

void WorkspaceModel::exportTo(const QString& exportPath) const noexcept
{
    auto importer = std::make_unique<Importer>();
    importer->exportWorkspaces(_workspacesPath, exportPath);
}

void WorkspaceModel::setVars(const QString& uuid, const QString& name, const QVariantMap& vars) noexcept
{
    QString wsName = name;
    QString nameForFile = wsName
                              .replace(" ", "_")
                              .toLower()
                              .append("_")
                              .append(uuid)
                              .append(".json");
    QString filePath = _workspacesPath + nameForFile;
    QJsonObject json = Util::getJsonFromFile(filePath);

    json["variables"] = QJsonObject::fromVariantMap(vars);

    emit varsUpdate(vars);
}

QVariantMap WorkspaceModel::getVars(const QString& uuid, const QString& name) const noexcept
{
    QString wsName = name;
    QString nameForFile = wsName
                              .replace(" ", "_")
                              .toLower()
                              .append("_")
                              .append(uuid)
                              .append(".json");
    QString filePath = _workspacesPath + nameForFile;
    QJsonObject json = Util::getJsonFromFile(filePath);

    return json["variables"].toObject().toVariantMap();
}

void WorkspaceModel::setWorkspace(int row)
{
    shared_ptr<Workspace> workspace = _workspaces.at(row);
    QString path = _workspacesPath + workspace->getFileName();
    QJsonObject json = Util::getJsonFromFile(path);

    if (json.isEmpty()) {
        return;
    }

    auto ws = make_shared<Workspace>();
    ws->fromJson(json);

    emit wsSet(ws);

    auto now = QDateTime::currentMSecsSinceEpoch();
    workspace->setLastUsageAt(now);

    QModelIndex idx = index(row, 0);
    emit dataChanged(idx, idx, {RoleNames::LastUsageRole});
}

void WorkspaceModel::filter(const QString& name)
{
    _workspaces = _allWorkspaces;

    beginResetModel();

    if (!name.trimmed().isEmpty()) {
        _workspaces.removeIf([&name](const auto& w) {
            return !w->name().toLower().contains(name.toLower());
        });
    }

    std::sort(_workspaces.begin(), _workspaces.end(), [&](auto& left, auto& right) {
        return left->lastUsageAt() > right->lastUsageAt();
    });

    endResetModel();
}

void WorkspaceModel::update(int idx, const QString& newName)
{
    QModelIndex index = createIndex(idx, 1);
    setData(index, newName);
}

void WorkspaceModel::create(const QString& name)
{
    auto workspace = std::make_shared<Workspace>();
    workspace->setUuid(Util::uuid());
    workspace->setName(name);
    workspace->setLastUsageAt(0);

    beginInsertRows(QModelIndex(), 0, 0);
    _workspaces.push_front(workspace);
    _allWorkspaces.push_front(workspace);
    endInsertRows();

    emit wsSave(workspace);
}
