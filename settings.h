#ifndef SETTINGS_H
#define SETTINGS_H

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>

#include "util.h"

class Settings : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString lastWorkspace READ lastWorkspace WRITE setLastWorkspace)

public:
    explicit Settings(QObject* parent = nullptr);

    void loadFromFile(const QString& filePath);
    QJsonObject toJson() const;

    // PROPERTY
    QString lastWorkspace() const;
    void setLastWorkspace(const QString& newLastWorkspace);

signals:
    void updateError(const QString&);

private:
    QString _lastWorkspace;

    void createDefault(const QString& filePath) noexcept;
};

#endif // SETTINGS_H
