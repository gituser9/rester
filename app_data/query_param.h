#ifndef QUERYPARAM_H
#define QUERYPARAM_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QJsonObject>

class QueryParam
{
    Q_GADGET

    Q_PROPERTY(bool isEnabled READ isEnabled WRITE setIsEnabled CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName)
    Q_PROPERTY(QString value READ value WRITE setValue)

public:
    QueryParam();
    QueryParam(const QJsonObject &json);
    QueryParam(const QVariantMap &map);
    QueryParam(const QString &name, const QString &value);
    QueryParam(const QString &name, const QString &value, bool isEnabled);
    QueryParam(std::initializer_list<QString> list);
    QueryParam(const QVariant &item);

    bool isEnabled() const;
    void setIsEnabled(bool newIsEnabled);

    QString name() const;
    void setName(const QString &newName);

    QString value() const;
    void setValue(const QString &newValue);

    QVariantMap toMap() const noexcept;
    void fromJson(QJsonObject json) noexcept;
    void fromVariantMap(QVariantMap json) noexcept;
    QJsonObject toJson() const noexcept;

private:
    bool _isEnabled;
    QString _name;
    QString _value;
};

Q_DECLARE_METATYPE(QueryParam)

#endif // QUERYPARAM_H
