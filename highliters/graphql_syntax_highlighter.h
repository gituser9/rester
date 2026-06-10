#ifndef GRAPHQL_SYNTAX_HIGHLIGHTER_H
#define GRAPHQL_SYNTAX_HIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QRegularExpression>
#include <QTextCharFormat>
#include <QQuickTextDocument>

#include "../app_data/highlighting_rule.h"

class GraphqlSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
public:
    explicit GraphqlSyntaxHighlighter(QQuickTextDocument* parent = nullptr);
    Q_INVOKABLE void setDocument(QQuickTextDocument* pDoc);

protected:
    void highlightBlock(const QString& text) override;

private:
    QList<HighlightingRule> highlightingRules;

    QTextCharFormat keywordFormat;
    QTextCharFormat variableFormat;
    QTextCharFormat directiveFormat;
    QTextCharFormat stringFormat;
    QTextCharFormat numberFormat;
    QTextCharFormat booleanNullFormat;
    QTextCharFormat commentFormat;
    QTextCharFormat punctuationFormat;
    QTextCharFormat argumentFormat;
    QTextCharFormat identifierFormat;
};

#endif // GRAPHQL_SYNTAX_HIGHLIGHTER_H
