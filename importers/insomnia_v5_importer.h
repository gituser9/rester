#ifndef INSOMNIA_V5_IMPORTER_H
#define INSOMNIA_V5_IMPORTER_H

#include <memory>

#include <QString>
#include <QFile>

#include <yaml-cpp/yaml.h>

#include "../app_data/workspace.h"
#include "../app_data/folder.h"
#include "../app_data/query.h"
#include "../util.h"

class InsomniaV5Importer
{
public:
    std::shared_ptr<Workspace> importWorkspace(const QString& path);

private:
    void processItems(
        const YAML::Node& items,
        Workspace* workspace,
        Folder* parentFolder //
    );
    void processRequest(
        const YAML::Node& node,
        Workspace* workspace,
        Folder* parentFolder //
    );
    void processFolder(
        const YAML::Node& node,
        Workspace* workspace,
        Folder* parentFolder //
    );
    BodyType detectBodyType(const YAML::Node& bodyNode);
    void setHeaders(const YAML::Node& headersNode, Query* query);
    void setParameters(const YAML::Node& parametersNode, Query* query);
};

#endif // INSOMNIA_V5_IMPORTER_H
