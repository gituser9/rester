#ifndef WORKSPACE_H
#define WORKSPACE_H

#include <unordered_map>

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QList>
#include <QObject>
#include <QStandardPaths>
#include <QString>
#include <qqml.h>

#include "../util.h"
#include "./constant.h"
#include "folder.h"
#include "query.h"

class Workspace : public TreeNode {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qint64 lastUsageAt READ lastUsageAt WRITE setLastUsageAt NOTIFY lastUsageAtChanged FINAL)
    Q_PROPERTY(QVariantMap variables READ variables WRITE setVariables NOTIFY variablesChanged FINAL)
    Q_PROPERTY(QString env READ env WRITE setEnv NOTIFY envChanged FINAL)
    Q_PROPERTY(QStringList pins READ pins WRITE setPins NOTIFY pinsChanged FINAL)

public:
    explicit Workspace(TreeNode* parent = nullptr);
    virtual ~Workspace() = default;

    void fromJson(const QJsonObject& json);
    void fromJsonShort(const QJsonObject& json) noexcept;
    void createDefault();
    void reloadVariables() noexcept;
    void setEnv(const QString& env) noexcept;
    QString getFileName() const;
    QList<TreeNode*> getAllFolders(TreeNode* node = nullptr);
    TreeNode* getByUuid(QString uuid) noexcept;
    TreeNode* getQueryByUuid(QString uuid) noexcept;
    InsomniaResource toInsomniaResource() const noexcept;
    static Workspace* getByQuery(TreeNode* query);

    // QML
    Q_INVOKABLE QJsonObject toJson();
    Q_INVOKABLE QStringList getEnvNames() const noexcept;
    Q_INVOKABLE void addPin(const QString& newPin);
    Q_INVOKABLE void removePin(const QString& pin);
    Q_INVOKABLE void removePin(int idx);
    Q_INVOKABLE QString nodeFullPath(const QString& uuid) noexcept;

    // PROPERTY
    void setLastUsageAt(qint64 newLastUsageAt);
    qint64 lastUsageAt() const;

    QVariantMap variables() const;
    void setVariables(const QVariantMap& newVariables);

    QString env() const;

    QStringList pins() const;
    void setPins(const QStringList& newPins);

public slots:

signals:
    void lastUsageAtChanged();
    void variablesChanged();
    void envChanged();
    void pinsChanged();

private:
    long long _lastUsageAt;
    QVariantMap _variables;
    QString _workspacesPath;
    QString _env;
    QStringList _pins;
    std::unordered_map<QString, QString> _variablesMap;

    void buildTree(const QJsonObject& json, TreeNode* parent);
    void buildFolder(const QJsonObject& json, TreeNode* parent);
    QJsonObject buildJsonTree(QObject* node) const;
    QJsonObject serializeNode(TreeNode* node) const;
    QJsonObject serializeFolder(Folder* node) const;
    QJsonObject serializeQuery(Query* node) const;
    QJsonObject serializeAnswer(HttpAnswer* node) const;
    TreeNode* getByUuid(QString uuid, TreeNode* node) const noexcept;
    TreeNode* getQueryByUuid(QString uuid, TreeNode* node) const noexcept;
    QString getParentName(const TreeNode* node) const noexcept;
};

#endif // WORKSPACE_H
