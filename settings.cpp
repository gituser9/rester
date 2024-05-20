#include "settings.h"

Settings::Settings(QObject* parent)
    : QObject { parent }
{
}

void Settings::loadFromFile(const QString& filePath)
{
    QJsonObject json = Util::getJsonFromFile(filePath);

    if (json.isEmpty()) {
        createDefault(filePath);
    }

    _lastWorkspace = json.value("last_workspace").toString("");
}

QString Settings::lastWorkspace() const
{
    return _lastWorkspace;
}

void Settings::setLastWorkspace(const QString& newLastWorkspace)
{
    _lastWorkspace = newLastWorkspace;
}

void Settings::createDefault(const QString& filePath) noexcept
{
    QFileInfo fi(filePath);
    QDir dir;

    if (!dir.exists(fi.absolutePath())) {
        dir.mkpath(fi.absolutePath());
        dir.mkpath(fi.absolutePath() + "/workspaces");
    }

    // fonts

    // json colors

    // xml  colors

    Util::writeJsonToFile(filePath, toJson());
}

QJsonObject Settings::toJson() const
{
    return {
        { "last_workspace", _lastWorkspace },
    };
}
