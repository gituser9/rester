#ifndef JSONSYNTAXHIGHLIGHTER_H
#define JSONSYNTAXHIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QQuickTextDocument>

#include "../app_data/highlighting_rule.h"

class JsonSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT

public:
    JsonSyntaxHighlighter(QQuickTextDocument* parent = nullptr);

    Q_INVOKABLE void setDocument(QQuickTextDocument* pDoc);

protected:
    void highlightBlock(const QString& text) override;

private:
    QList<HighlightingRule> highlightingRules;

    QTextCharFormat keywordFormat;
    QTextCharFormat fieldNameFormat;
    QTextCharFormat fieldValueFormat;
    QTextCharFormat numberFormat;
    QTextCharFormat arrayObjectFormat;
    QTextCharFormat indentationFormat;
    QTextCharFormat objectFormat;
    QTextCharFormat arrayFormat;
};

#endif // JSONSYNTAXHIGHLIGHTER_H
