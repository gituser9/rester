#ifndef SEARCHSYNTAXHIGHLIGHTER_H
#define SEARCHSYNTAXHIGHLIGHTER_H

#include <QtQmlIntegration/qqmlintegration.h>
#include <QSyntaxHighlighter>
#include <QTextCharFormat>

#include "../app_data/highlighting_rule.h"

class SearchSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT

public:
    SearchSyntaxHighlighter(QTextDocument* parent = nullptr);

    void setWordPattern(const QString& word);
    void highlightBlock(const QString& text);
    void setNextMatchStateActive();
    void setPrevMatchStateActive();
    void setActiveMatchIndex(int activeMatchIndex);
    void customRehighlight();
    int totalMatches() const;
    int activeMatchIndex() const;
    int currentCursorMatch() const;
    int currentLineMatch() const;

private:
    QString _findString;
    QRegularExpressionMatchIterator _matches;
    QList<QRegularExpressionMatch> _matchList;
    QTextBlock _activeBlock;
    HighlightingRule _defaultHighlightingRule;
    HighlightingRule _activeHighlightingRule;
    int _currentMatchIndex = 0;
    int _activeMatchIndex = 0;
    int _currentCursorMatch = -1;
    int _currentLineMatch = -1;
};

#endif // SEARCHSYNTAXHIGHLIGHTER_H
