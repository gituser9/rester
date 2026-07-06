#ifndef CONSTANT_H
#define CONSTANT_H

#include <QObject>
#include <qqmlintegration.h>

class RstEnums : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("RstEnums provides only enums")

public:
    explicit RstEnums(QObject* parent = nullptr) : QObject(parent)
    {
    }

    enum class BodyType {
        NONE = 0,
        JSON = 1,
        MULTIPART_FORM = 2,
        URL_ENCODED_FORM = 3,
        XML = 4,
        HTML = 5,
        GRAPHQL = 6
    };
    Q_ENUM(BodyType)

    enum class ImportType {
        Rester = 0,
        Postman = 1,
        InsomniaV5 = 2,
        Swagger = 3,
        Har = 4
    };
    Q_ENUM(ImportType)

    enum class QueryType {
        GET = 0,
        POST = 1,
        PUT = 2,
        PATCH = 3,
        DELETE = 4,
        HEAD = 5,
        WS = 6,
        GRPC = 7,
        GRAPHQL = 8
    };
    Q_ENUM(QueryType)

    enum class NodeType {
        FolderNode = 0,
        QueryNode = 1,
        GrpcQueryNode = 2,
        GraphqlQueryNode = 3,
    };
    Q_ENUM(NodeType)
};

class RstConstant : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    static inline const QString varRegexPattern = "{{\\s*(.*?)\\s*}}";
};

#endif // CONSTANT_H
