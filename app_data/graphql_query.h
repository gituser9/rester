#ifndef GRAPHQL_QUERY_H
#define GRAPHQL_QUERY_H

#include <QString>
#include <QList>
#include <QVariant>
#include <QVariantList>
#include <QSharedPointer>

#include "tree_node.h"
#include "http_answer.h"

class GraphqlQuery : public TreeNode
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QueryType queryType READ queryType)
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString body READ body WRITE setBody NOTIFY bodyChanged)
    Q_PROPERTY(QVariantList headers READ headers WRITE setHeaders NOTIFY headersChanged)
    Q_PROPERTY(QVariantList variables READ variables WRITE setVariables NOTIFY variablesChanged)
    Q_PROPERTY(HttpAnswer* lastAnswer READ lastAnswer WRITE setLastAnswer NOTIFY lastAnswerChanged)

public:
    explicit GraphqlQuery(TreeNode* parent = nullptr);
    ~GraphqlQuery() override;

    // Properties
    QueryType queryType() const;

    QString url() const;
    void setUrl(const QString& newUrl);

    QString body() const;
    void setBody(const QString& newBody);

    QVariantList headers() const;
    void setHeaders(const QVariantList& newHeaders);
    void setHeaders(const QList<QueryParam>& newHeaders);

    QVariantList variables() const;
    void setVariables(const QVariantList& newVariables);

    HttpAnswer* lastAnswer() const;
    void setLastAnswer(HttpAnswer* newLastAnswer);
    void setLastAnswer(QSharedPointer<HttpAnswer> ptr);

    // Custom
    QList<QueryParam> headerList() const noexcept;
    QList<QueryParam> variablesList() const noexcept;

    // For QML
    Q_INVOKABLE void addHeader(const QString& name, const QString& value);
    Q_INVOKABLE void addHeader(const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void setHeader(int index, const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void removeHeader(int index);
    Q_INVOKABLE void removeHeader(const QString& name);

    Q_INVOKABLE void addVariable(const QString& name, const QString& value);
    Q_INVOKABLE void addVariable(const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void setVariable(int index, const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void removeVariable(int index);
    Q_INVOKABLE void removeVariable(const QString& name);

    // Methods
    void fromJson(QJsonObject json);
    QJsonObject toJson() const;

signals:
    void urlChanged();
    void bodyChanged();
    void headersChanged();
    void variablesChanged();
    void lastAnswerChanged();
    void dataChanged();

private:
    QueryType _queryType;
    QString _url;
    QString _body;
    QList<QueryParam> _headers;
    QList<QueryParam> _variables;
    QSharedPointer<HttpAnswer> _lastAnswer = nullptr;
};

#endif // GRAPHQL_QUERY_H
