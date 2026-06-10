#ifndef CONSTANT_H
#define CONSTANT_H

enum NodeType { // TODO: enum class
    FolderNode = 0,
    QueryNode = 1,
    GrpcQueryNode = 2,
    GraphqlQueryNode = 3,
};

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

enum class BodyType {
    NONE = 0,
    JSON = 1,
    MULTIPART_FORM = 2,
    URL_ENCODED_FORM = 3,
    XML = 4,
    HTML = 5,
    GRAPHQL = 6
};

enum class ImportType {
    Rester = 0,
    Postman = 1,
    InsomniaV5 = 2,
    Swagger = 3,
    Har = 4
};

#endif // CONSTANT_H
