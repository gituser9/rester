#ifndef SETTINGS_STRUCTS_H
#define SETTINGS_STRUCTS_H

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>

struct Color {
    QString color;
    int weight;

    void fromJson(const QJsonObject& json) noexcept {
        color = json["color"].toString();
        weight = json["weight"].toInt();
    }

    QJsonObject toJson() const noexcept {
        return {
            { "color", color },
            { "weight", weight },
        };
    }
};

struct Font {
    QString family;
    int size;

    void fromJson(const QJsonObject& json) noexcept {
        family = json["family"].toString();
        size = json["size"].toInt();
    }

    QJsonObject toJson() const noexcept {
        return {
            { "family", family },
            { "size", size },
        };
    }
};

struct JsonColors {
    Color fieldColor;
    Color stringColor;
    Color numberColor;
    Color figureBrackets;
    Color squareBrackets;

    void fromJson(const QJsonObject& json) noexcept {
        fieldColor.fromJson(json["field_color"].toObject());
        stringColor.fromJson(json["string_color"].toObject());
        numberColor.fromJson(json["number_color"].toObject());
        figureBrackets.fromJson(json["figure_brackets"].toObject());
        squareBrackets.fromJson(json["square_brackets"].toObject());
    }

    QJsonObject toJson() const noexcept {
        return {
            { "field_color", fieldColor.toJson()},
            { "string_color", stringColor.toJson()},
            { "number_color", numberColor.toJson()},
            { "figure_brackets", figureBrackets.toJson()},
            { "square_brackets", squareBrackets.toJson()},
        };
    }
};

struct XmlColors {
    Color tag;
    Color attribute;
    Color attributeValue;

    void fromJson(const QJsonObject& json) noexcept {
        tag.fromJson(json["tag"].toObject());
        attribute.fromJson(json["attribute"].toObject());
        attributeValue.fromJson(json["attribute_value"].toObject());
    }

    QJsonObject toJson() const noexcept {
        return {
            { "tag", tag.toJson()},
            { "attribute", attribute.toJson()},
            { "attribute_value", attributeValue.toJson()},
        };
    }
};

struct Fonts
{
    Font interface;
    Font monospace;

    void fromJson(const QJsonObject& json) noexcept {
        interface.fromJson(json["interface"].toObject());
        monospace.fromJson(json["monospace"].toObject());
    }

    QJsonObject toJson() const noexcept {
        return {
            { "interface", interface.toJson()},
            { "monospace", monospace.toJson()},
        };
    }
};

struct Colors
{
    XmlColors xml;
    JsonColors json;

    void fromJson(const QJsonObject& json) noexcept {
        this->json.fromJson(json["json"].toObject());
        xml.fromJson(json["xml"].toObject());
    }

    QJsonObject toJson() const noexcept {
        return {
            { "json", this->json.toJson()},
            { "xml", xml.toJson()},
        };
    }
};

struct Ui {
    Fonts fonts;
    Colors colors;

    static Ui createDefault() {
        Ui ui;
        return ui;
    }

    void fromJson(const QJsonObject& json) noexcept {
        fonts.fromJson(json["fonts"].toObject());
        colors.fromJson(json["colors"].toObject());
    }

    QJsonObject toJson() const noexcept {
        return {
            { "fonts", fonts.toJson()},
            { "colors", colors.toJson()},
        };
    }
};


#endif // SETTINGS_STRUCTS_H
