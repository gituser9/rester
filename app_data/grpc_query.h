#ifndef GRPCQUERY_H
#define GRPCQUERY_H

#include <QString>
#include <QSharedPointer>

#include "tree_node.h"
#include "http_answer.h"

class GrpcQuery : public TreeNode
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(RstEnums::QueryType queryType READ queryType)
    Q_PROPERTY(QString url READ url WRITE setUrl NOTIFY urlChanged)
    Q_PROPERTY(QString rpc READ rpc WRITE setRpc NOTIFY rpcChanged)
    Q_PROPERTY(QStringList availableRpc READ availableRpc NOTIFY availableRpcChanged)
    Q_PROPERTY(QString srv READ srv WRITE setSrv NOTIFY srvChanged)
    Q_PROPERTY(QStringList availableSrv READ availableSrv WRITE setAvailableSrv NOTIFY availableSrvChanged)
    Q_PROPERTY(QVariantList meta READ meta WRITE setMeta NOTIFY metaChanged)
    Q_PROPERTY(QString body READ body WRITE setBody NOTIFY bodyChanged)
    Q_PROPERTY(QString package READ package WRITE setPackage NOTIFY packageChanged)
    Q_PROPERTY(QString filePath READ filePath WRITE setFilePath NOTIFY filePathChanged)
    Q_PROPERTY(HttpAnswer* lastAnswer READ lastAnswer WRITE setLastAnswer NOTIFY lastAnswerChanged)

public:
    explicit GrpcQuery(TreeNode* parent = nullptr);
    virtual ~GrpcQuery();

    // Properties
    RstEnums::QueryType queryType() const;

    QString url() const;
    void setUrl(const QString& newUrl);

    QString rpc() const;
    void setRpc(const QString& newRpc);

    QStringList availableRpc() const;
    void setAvailableRpc(const QMap<QString, QStringList>& newRpc);

    QString srv() const;
    void setSrv(const QString& newSrv);

    QStringList availableSrv() const;
    void setAvailableSrv(const QStringList& newSrv);

    QVariantList meta() const;
    QList<QueryParam> metaList() const;
    void setMeta(const QVariantList& newMeta);
    void setMeta(const QList<QueryParam>& newMeta);

    QString body() const;
    void setBody(const QString& newBody);

    QString package() const;
    void setPackage(const QString& newPackage);

    QString filePath() const;
    void setFilePath(const QString& newPackage);

    HttpAnswer* lastAnswer() const;
    void setLastAnswer(HttpAnswer* newLastAnswer);
    void setAnswer(QSharedPointer<HttpAnswer> ptr);

    // QML
    Q_INVOKABLE void setMetaItem(int index, const QString& name, const QString& value, bool isEnabled);
    Q_INVOKABLE void removeMetaItem(int index);
    Q_INVOKABLE void addMetaItem(const QString& name, const QString& value);

    // Methods
    void fromJson(QJsonObject json);
    QJsonObject toJson() const;

signals:
    void dataChanged();
    void urlChanged();
    void rpcChanged();
    void availableRpcChanged();
    void srvChanged();
    void availableSrvChanged();
    void metaChanged();
    void bodyChanged();
    void packageChanged();
    void filePathChanged();
    void lastAnswerChanged();

private:
    RstEnums::QueryType _queryType;

    QString _srv;
    QString _url;
    QString _package;
    QString _filePath;
    QString _rpc;

    QStringList _availableSrv;
    QMap<QString, QString> _availableBody;
    QMap<QString, QStringList> _availableRpc;
    QMap<QString, QList<QueryParam>> _availableMeta;
    QMap<QString, QSharedPointer<HttpAnswer>> _availableLastAnswer;
};

#endif
