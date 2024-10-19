#ifndef QUERY_H
#define QUERY_H

#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QObject>
#include <QSharedPointer>
#include <QUuid>
#include <QVariantMap>
#include <qqml.h>

#include "../util.h"
#include "constant.h"
#include "http_answer.h"
#include "query_param.h"
#include "tree_node.h"

class Query : public TreeNode {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QueryType queryType READ queryType WRITE setQueryType NOTIFY queryTypeChanged)
    Q_PROPERTY(BodyType bodyType READ bodyType WRITE setBodyType NOTIFY bodyTypeChanged)
    Q_PROPERTY(QVariantList params READ params WRITE setParams NOTIFY paramsChanged)
    Q_PROPERTY(QVariantList headers READ headers WRITE setHeaders NOTIFY headersChanged)
    Q_PROPERTY(QString body READ body WRITE setBody NOTIFY bodyChanged)
    Q_PROPERTY(HttpAnswer* lastAnswer READ lastAnswer WRITE setLastAnswer NOTIFY lastAnswerChanged)
    Q_PROPERTY(QVariantList formData READ formData WRITE setFormData NOTIFY formDataChanged FINAL)

public:
    explicit Query(TreeNode* parent = nullptr);
    virtual ~Query();

    // Properties
    QString url() const;
    void setUrl(const QString& newUrl);

    QueryType queryType() const;
    void setQueryType(QueryType newQueryType);

    BodyType bodyType() const;
    void setBodyType(BodyType newBodyType);

    QVariantList params() const;
    void setParams(const QVariantList& newParams);

    QVariantList headers() const;
    void setHeaders(const QVariantList& newHeaders);

    QString body() const;
    void setBody(const QString& newBody);

    HttpAnswer* lastAnswer() const;
    void setLastAnswer(HttpAnswer* newLastAnswer);

    void fromJson(QJsonObject json);
    QJsonObject toJson() const;

    void setAnswer(QSharedPointer<HttpAnswer> ptr);
    // QVariant getHeader(const QString& name) const;

    QVariantList formData() const;
    void setFormData(const QVariantList& newFormData);

    void parseParams() noexcept;
    QString fileNameForAnswer() const noexcept;

    // Custom
    QList<QueryParam> paramList() const noexcept;
    QList<QueryParam> headerList() const noexcept;
    InsomniaResource toInsomniaResource(const QString& parentId) const noexcept;
    PostmanItem toPostmanItem() const noexcept;

    // For QML
    Q_INVOKABLE void beautify() noexcept;
    Q_INVOKABLE void addHeader(const QString& name, const QString& value);
    Q_INVOKABLE void addParam(const QString& name, const QString& value);
    Q_INVOKABLE void addFormData(const QString& name, const QString& value);
    Q_INVOKABLE void removeParam(int index);
    Q_INVOKABLE void removeHeader(int index);
    Q_INVOKABLE void removeFormDateItem(int index);
    Q_INVOKABLE void setParam(int index, const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void setHeader(int index, const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void setFormDataItem(int index, const QString& name, const QString& value, bool isEnabled);

signals:
    void urlChanged();
    void queryTypeChanged();
    void bodyTypeChanged();
    void paramsChanged();
    void headersChanged();
    void bodyChanged();
    void lastAnswerChanged();
    void dataChanged();
    void formDataChanged();

private:
    QString _url;
    QueryType _queryType;
    BodyType _bodyType;
    QList<QueryParam> _headers;
    QString _body;
    QSharedPointer<HttpAnswer> _lastAnswer;
    QList<QueryParam> _paramList;
    QList<QueryParam> _formDataList;

    QSharedPointer<InsomniaBody> buildInsomniaBody() const noexcept;
};

#endif // QUERY_H
