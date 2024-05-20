#include "query_param.h"

QueryParam::QueryParam()
{
    _isEnabled = true;
}

QueryParam::QueryParam(const QJsonObject& json)
{
    _isEnabled = json["is_enabled"].toBool(true);
    _name = json["name"].toString();
    _value = json["value"].toString();
}

QueryParam::QueryParam(const QVariantMap& map)
{
    _isEnabled = map["isEnabled"].toBool();
    _name = map["name"].toString();
    _value = map["value"].toString();
}

QueryParam::QueryParam(const QString& name, const QString& value)
    : _name { name }
    , _value { value }
{
    _isEnabled = true;
}

QueryParam::QueryParam(const QString& name, const QString& value, bool isEnabled)
    : _isEnabled { isEnabled }
    , _name { name }
    , _value { value }
{
}

QueryParam::QueryParam(std::initializer_list<QString> list)
{
    // for (const QString& i : list) {
    //     if (_name.isEmpty()) {
    //         _name = i;
    //     }

    //     if (_value.isEmpty()) {
    //         _value = i;
    //     }
    // }
    if (list.size() == 3) {
        auto it = list.begin();
        _isEnabled = it[0].toInt();
        _name = *(++it);
        _value = *(++it);
    }
}

QueryParam::QueryParam(const QVariant& item)
{
    if (item.canConvert<QueryParam>()) {
        auto p = item.value<QueryParam>();
        _name = p.name();
        _value = p.value();
        _isEnabled = p.isEnabled();
    } else {
        QVariantMap map = item.toMap();
        _isEnabled = map["isEnabled"].toBool();
        _name = map["name"].toString();
        _value = map["value"].toString();
    }
}

bool QueryParam::isEnabled() const
{
    return _isEnabled;
}

void QueryParam::setIsEnabled(bool newIsEnabled)
{
    if (_isEnabled == newIsEnabled) {
        return;
    }

    _isEnabled = newIsEnabled;
}

QString QueryParam::name() const
{
    return _name;
}

void QueryParam::setName(const QString& newName)
{
    if (_name == newName) {
        return;
    }

    _name = newName;
}

QString QueryParam::value() const
{
    return _value;
}

void QueryParam::setValue(const QString& newValue)
{
    if (_value == newValue) {
        return;
    }

    _value = newValue;
}

QVariantMap QueryParam::toMap() const noexcept
{
    return {
        { "isEnabled", _isEnabled },
        { "name", _name },
        { "value", _value },
    };
}

void QueryParam::fromJson(QJsonObject json) noexcept
{
    _isEnabled = json["is_enabled"].toBool(true);
    _name = json["name"].toString();
    _value = json["value"].toString();
}

void QueryParam::fromVariantMap(QVariantMap json) noexcept
{
    _isEnabled = json["is_enabled"].toBool();
    _name = json["name"].toString();
    _value = json["value"].toString();
}

QJsonObject QueryParam::toJson() const noexcept
{
    return {
        { "is_enabled", _isEnabled },
        { "name", _name },
        { "value", _value },
    };
}
