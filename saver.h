#ifndef SAVER_H
#define SAVER_H

#include <memory>

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QObject>

#include "app_data/workspace.h"
#include "settings.h"

class Saver : public QObject {
    Q_OBJECT

public:
    explicit Saver(QObject* parent = nullptr);

public slots:
    void saveWorkspace(std::shared_ptr<Workspace> workspace) noexcept;
    void saveSettings(std::shared_ptr<Settings> settings) noexcept;

signals:
    void saveError(const QString&);

private:
    QString _configDirPath;

    void saveRaw(const QJsonObject& json, const QString& filePath) noexcept;
};

#endif // SAVER_H
