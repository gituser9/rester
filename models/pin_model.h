#ifndef PINMODEL_H
#define PINMODEL_H

#include <memory>

#include <QAbstractListModel>

#include "../app_data/workspace.h"

class PinModel : public QAbstractListModel {
    Q_OBJECT

public:
    explicit PinModel(QObject* parent = nullptr);

    // Basic functionality:
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;

    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;

    // Add data:
    Q_INVOKABLE void addPin(const QString& uuid) noexcept;

    // Remove data:
    Q_INVOKABLE bool removeRows(int row, int count, const QModelIndex& parent = QModelIndex()) override;

public slots:
    void setWorkspace(std::shared_ptr<Workspace> workspace) noexcept;
    void remove(const QString& pin);

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    enum class RoleNames {
        NameRole = Qt::UserRole,
        UuidRole = Qt::UserRole + 1,
    };
    QHash<int, QByteArray> _names;
    std::shared_ptr<Workspace> _workspace;
};

#endif // PINMODEL_H
