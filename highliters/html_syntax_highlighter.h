#ifndef HTMLSYNTAXHIGHLIGHTER_H
#define HTMLSYNTAXHIGHLIGHTER_H

#include <QObject>
#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QTextDocument>
#include <QRegularExpression>
#include <QQuickTextDocument>


class HtmlSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT

public:
    HtmlSyntaxHighlighter(QQuickTextDocument *parent = nullptr);

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

    QTextCharFormat tagFormat;
    QTextCharFormat attributeFormat;
    QTextCharFormat attributeValueFormat;
    QTextCharFormat valueFormat;
};
#endif // HTMLSYNTAXHIGHLIGHTER_H
