#include "pin_model.h"

PinModel::PinModel(QObject* parent)
    : QAbstractListModel(parent)
{
    _names[static_cast<int>(RoleNames::NameRole)] = "name";
    _names[static_cast<int>(RoleNames::UuidRole)] = "uuid";
}

int PinModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    if (!_workspace) {
        return 0;
    }

    return _workspace->pins().count();
}

QVariant PinModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    auto enumRole = static_cast<RoleNames>(role);
    QString uuid = _workspace->pins().at(index.row());
    QString name = _workspace->nodeFullPath(uuid);

    switch (enumRole) {
    case RoleNames::NameRole:
        return name;
    case RoleNames::UuidRole:
        return uuid;
    }

    return {};
}

void PinModel::addPin(const QString& uuid) noexcept
{
    int row = _workspace->pins().size();

    beginInsertRows(QModelIndex(), row, row);
    _workspace->addPin(uuid);
    endInsertRows();
}

bool PinModel::removeRows(int row, int count, const QModelIndex& parent)
{
    beginRemoveRows(parent, row, row + count - 1);
    _workspace->removePin(row);
    endRemoveRows();

    return true;
}

void PinModel::remove(const QString& pin)
{
    auto pins = _workspace->pins();

    for (qsizetype i = 0; i < pins.size(); ++i) {
        if (pins[i] != pin) {
            continue;
        }

        removeRows(i, 1);
        break;
    }
}

QHash<int, QByteArray> PinModel::roleNames() const
{
    return _names;
}

void PinModel::setWorkspace(std::shared_ptr<Workspace> workspace) noexcept
{
    beginResetModel();
    _workspace = workspace;
    endResetModel();
}
