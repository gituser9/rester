#ifndef URL_HIGHLIGHTER_H
#define URL_HIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QQuickTextDocument>

#include "../app_data/highlighting_rule.h"

class UrlHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT

public:
    explicit UrlHighlighter(QQuickTextDocument* parent = nullptr);

    Q_INVOKABLE void setDocument(QQuickTextDocument* pDoc);

protected:
    QList<HighlightingRule> highlightingRules;
    QTextCharFormat schemeFormat;
    QTextCharFormat hostFormat;
    QTextCharFormat portFormat;
    QTextCharFormat pathFormat;
    QTextCharFormat queryKeyFormat;
    QTextCharFormat queryValueFormat;
    QTextCharFormat fragmentFormat;
    QTextCharFormat delimiterFormat;

    void highlightBlock(const QString& text) override;
};

#endif // URL_HIGHLIGHTER_H
