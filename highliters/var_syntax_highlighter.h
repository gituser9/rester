#ifndef VARSYNTAXHIGHLIGHTER_H
#define VARSYNTAXHIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QQuickTextDocument>
#include <QRegularExpression>
#include <QTextCharFormat>

class VarSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT


public:
    explicit VarSyntaxHighlighter(QQuickTextDocument *parent = nullptr);

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
    QTextCharFormat varFormat;
};

#endif // VARSYNTAXHIGHLIGHTER_H
