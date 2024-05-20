#ifndef JSONSYNTAXHIGHLIGHTER_H
#define JSONSYNTAXHIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QTextDocument>
#include <QRegularExpression>
#include <QQuickTextDocument>

class JsonSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT


public:
    JsonSyntaxHighlighter(QQuickTextDocument *parent = nullptr);

    Q_INVOKABLE void setDocument(QQuickTextDocument *pDoc);


protected:
    void highlightBlock(const QString &text) override;


private:
    struct HighlightingRule
    {
        QRegularExpression pattern;
        QTextCharFormat format;
    };

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
