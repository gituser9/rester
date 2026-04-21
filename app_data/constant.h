#ifndef CONSTANT_H
#define CONSTANT_H

enum NodeType { // TODO: enum class
    FolderNode = 0,
    QueryNode,
    GrpcQueryNode,
};

enum class QueryType {
    GET = 0,
    POST = 1,
    PUT = 2,
    PATCH = 3,
    DELETE = 4,
    HEAD = 5,
    WS = 6,
    GRPC = 7
};

enum class BodyType {
    NONE = 0,
    JSON,
    MULTIPART_FORM,
    URL_ENCODED_FORM,
    XML,
    HTML
};

enum class ImportType {
    Rester = 0,
    Insomnia = 1,
    Postman = 2,
};

#endif // CONSTANT_H
