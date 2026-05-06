#include "insomnia_v5_importer.h"

std::shared_ptr<Workspace> InsomniaV5Importer::importWorkspace(const QString& path)
{
    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        return nullptr;
    }

    QByteArray data = file.readAll();
    file.close();

    std::string yamlStr = data.toStdString();
    YAML::Node root;

    try {
        root = YAML::Load(yamlStr);
    }
    catch (const YAML::Exception& e) {
        return nullptr;
    }

    if (!root.IsMap()) {
        return nullptr;
    }

    auto workspace = std::make_shared<Workspace>();
    workspace->createDefault();

    auto wsName = root["name"].as<std::string>("Insomnia Workspace");
    workspace->setName(QString::fromStdString(wsName));
    workspace->setUuid(Util::uuid());

    YAML::Node collection = root["collection"];

    if (!collection || !collection.IsSequence()) {
        return workspace;
    }

    processItems(collection, workspace.get(), nullptr);

    return workspace;
}

void InsomniaV5Importer::processItems(
    const YAML::Node& items,
    Workspace* workspace,
    Folder* parentFolder //
)
{
    if (!items || !items.IsSequence()) {
        return;
    }

    for (const auto& item : items) {
        if (!item || !item.IsMap()) {
            continue;
        }

        // is folder
        if (item["children"]) {
            processFolder(item, workspace, parentFolder);
        }
        // is query
        else if (item["url"]) {
            processRequest(item, workspace, parentFolder);
        }
    }
}

void InsomniaV5Importer::processFolder(
    const YAML::Node& node,
    Workspace* workspace,
    Folder* parentFolder //
)
{
    auto folder = new Folder(parentFolder ? static_cast<TreeNode*>(parentFolder) : static_cast<TreeNode*>(workspace));
    folder->setName(QString::fromStdString(node["name"].as<std::string>("Unnamed Folder")));
    folder->setUuid(Util::uuid());
    folder->setNodeType(NodeType::FolderNode);

    if (parentFolder) {
        parentFolder->addNode(folder);
        folder->setParent(parentFolder);
    }
    else {
        workspace->addNode(folder);
        folder->setParent(workspace);
    }

    // nested folder
    YAML::Node children = node["children"];

    if (children && children.IsSequence()) {
        processItems(children, workspace, folder);
    }
}

void InsomniaV5Importer::processRequest(
    const YAML::Node& node,
    Workspace* workspace,
    Folder* parentFolder //
)
{
    auto query = new Query();
    query->setUuid(Util::uuid());
    query->setNodeType(NodeType::QueryNode);

    auto reqName = node["name"].as<std::string>("Unnamed Request");
    query->setName(QString::fromStdString(reqName));

    auto url = node["url"].as<std::string>("");
    query->setUrl(QString::fromStdString(url));

    auto method = node["method"].as<std::string>("GET");
    query->setQueryType(Util::getQueryType(QString::fromStdString(method).toUpper()));

    if (node["headers"]) {
        setHeaders(node["headers"], query);
    }

    if (node["parameters"]) {
        setParameters(node["parameters"], query);
    }

    if (node["body"]) {
        const YAML::Node& body = node["body"];
        BodyType bodyType = detectBodyType(body);
        query->setBodyType(bodyType);

        if (bodyType == BodyType::JSON) {
            auto text = body["text"].as<std::string>("{}");
            query->setBody(QString::fromStdString(text));
        }
        else if (bodyType == BodyType::MULTIPART_FORM) {
            const YAML::Node& paramsNode = body["params"];

            for (const auto& node : paramsNode) {
                if (!node || !node.IsMap()) {
                    continue;
                }

                bool disabled = node["disabled"].as<bool>(false);
                auto name = node["name"].as<std::string>("");
                auto value = node["value"].as<std::string>("");

                query->addFormData(
                    QString::fromStdString(name),
                    QString::fromStdString(value),
                    !disabled //
                );
            }

            query->setBody(QString());
        }
        else {
            auto text = body["text"].as<std::string>("");
            query->setBody(QString::fromStdString(text));
        }
    }

    if (parentFolder) {
        query->setParent(parentFolder);
        parentFolder->addNode(query);
    }
    else {
        query->setParent(workspace);
        workspace->addNode(query);
    }
}

BodyType InsomniaV5Importer::detectBodyType(const YAML::Node& bodyNode)
{
    if (!bodyNode || !bodyNode.IsMap()) {
        return BodyType::NONE;
    }

    auto mimeType = bodyNode["mimeType"].as<std::string>("");

    if (mimeType.empty()) {
        return BodyType::NONE;
    }

    if (mimeType.find("json") != std::string::npos) {
        return BodyType::JSON;
    }

    if (mimeType.find("multipart/form-data") != std::string::npos) {
        return BodyType::MULTIPART_FORM;
    }

    if (mimeType.find("x-www-form-urlencoded") != std::string::npos) {
        return BodyType::URL_ENCODED_FORM;
    }

    if (mimeType.find("xml") != std::string::npos) {
        return BodyType::XML;
    }

    return BodyType::NONE;
}

void InsomniaV5Importer::setHeaders(const YAML::Node& headersNode, Query* query)
{
    if (!headersNode || !headersNode.IsSequence()) {
        return;
    }

    for (const auto& node : headersNode) {
        if (!node || !node.IsMap()) {
            continue;
        }

        bool disabled = node["disabled"].as<bool>(false);
        auto name = node["name"].as<std::string>("");
        auto value = node["value"].as<std::string>("");

        if (name.empty()) {
            continue;
        }

        query->addHeader(
            QString::fromStdString(name),
            QString::fromStdString(value),
            !disabled //
        );
    }
}

void InsomniaV5Importer::setParameters(const YAML::Node& parametersNode, Query* query)
{
    if (!parametersNode || !parametersNode.IsSequence()) {
        return;
    }

    for (const auto& node : parametersNode) {
        if (!node || !node.IsMap()) {
            continue;
        }

        bool disabled = node["disabled"].as<bool>(false);
        auto name = node["name"].as<std::string>("");
        auto value = node["value"].as<std::string>("");

        if (name.empty()) {
            continue;
        }

        query->addParam(
            QString::fromStdString(name),
            QString::fromStdString(value),
            !disabled //
        );
    }
}
