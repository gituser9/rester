#include "saver.h"

Saver::Saver(QObject* parent)
    : QObject { parent }
{
    QStringList cfgLocation = QStandardPaths::standardLocations(QStandardPaths::ConfigLocation);
    _configDirPath = cfgLocation.first() + "/rester";
}

void Saver::saveWorkspace(std::shared_ptr<Workspace> workspace) noexcept
{
    QString filePath = _configDirPath + "/workspaces/" + workspace->getFileName();

    saveRaw(workspace->toJson(), filePath);
}

void Saver::saveRaw(const QJsonObject& json, const QString& filePath) noexcept
{
    QJsonDocument doc(json);
    QFile file(filePath);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit saveError(QString("save %1 error").arg(filePath));

        return;
    }

    QTextStream outStream(&file);
    QString data = QString(doc.toJson())
                       .replace("&quot;", R"(\")")
                       .replace("\\n\\n", "");

    outStream << data;

    file.close();
}

void Saver::saveSettings(std::shared_ptr<Settings> settings) noexcept
{
    saveRaw(settings->toJson(), _configDirPath + "/settings.json");
}
