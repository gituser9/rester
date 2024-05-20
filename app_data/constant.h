#ifndef CONSTANT_H
#define CONSTANT_H


enum NodeType {
    FolderNode = 0,
    QueryNode
};

enum class QueryType {
    GET = 0,
    POST,
    PUT,
    PATCH,
    DELETE,
    HEAD,
    WS
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
