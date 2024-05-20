#include "search_syntax_highlighter.h"


SearchSyntaxHighlighter::SearchSyntaxHighlighter(QTextDocument *parent) : QSyntaxHighlighter{parent}
{
    _defaultHighlightingRule.format.setBackground(QColor(128, 128, 128, 128));
    _defaultHighlightingRule.format.setFontWeight(QFont::Bold);

    _activeHighlightingRule.format.setBackground(QColor(255, 165, 0));
    _activeHighlightingRule.format.setFontWeight(QFont::Bold);
}

void SearchSyntaxHighlighter::setWordPattern(const QString& pattern)
{
    if (pattern != _findString) {
        _findString = pattern;
        _defaultHighlightingRule.pattern = QRegularExpression(pattern, QRegularExpression::PatternOption::CaseInsensitiveOption);
        _activeMatchIndex = 0;
    }
}

void SearchSyntaxHighlighter::highlightBlock(const QString& text)
{
    if(!document()) {
        return;
    }

    if (_findString.isEmpty()) {
        setFormat(0, document()->toPlainText().length(), QTextCharFormat());

        _activeMatchIndex = 0;
    } else {
        _matches = _defaultHighlightingRule.pattern.globalMatch(text);

        while (_matches.hasNext()) {
            QRegularExpressionMatch match = _matches.next();

            if (match.hasPartialMatch() || match.hasMatch()) {
                int startOffset = match.capturedStart();
                int endOffset   = match.capturedEnd();
                QTextCharFormat format = _defaultHighlightingRule.format;

                if (_activeMatchIndex == _currentMatchIndex) {
                    format = _activeHighlightingRule.format;
                    _activeBlock = currentBlock();
                }

                setFormat(startOffset, endOffset - startOffset, format);
                _matchList.push_back(match);

                ++_currentMatchIndex;
            }
        }
    }
}

void SearchSyntaxHighlighter::customRehighlight()
{
    if (!document()) {
        return;
    }

    _matchList.clear();
    _currentMatchIndex = 0;

    rehighlight();
}

void SearchSyntaxHighlighter::setNextMatchStateActive()
{
    setActiveMatchIndex(_activeMatchIndex + 1);
}

void SearchSyntaxHighlighter::setPrevMatchStateActive()
{
    setActiveMatchIndex(_activeMatchIndex - 1);
}

void SearchSyntaxHighlighter::setActiveMatchIndex(int activeMatchIndex)
{
    if (_activeMatchIndex != activeMatchIndex) {
        if (activeMatchIndex >= 0 && activeMatchIndex < _matchList.size()) {
            _activeMatchIndex = activeMatchIndex;

            customRehighlight();
        } else if(activeMatchIndex >= _matchList.size() && _matchList.size() > 0) {
            _activeMatchIndex = 0;

            customRehighlight();
        } else if(activeMatchIndex <= -1 && _matchList.size() > 0) {
            _activeMatchIndex = _matchList.size() - 1;

            customRehighlight();
        }
    }

    if (_activeMatchIndex >= 0 && _activeMatchIndex < _matchList.size() && !_findString.isEmpty()) {
        _currentCursorMatch = _matchList[_activeMatchIndex].capturedEnd() + _activeBlock.position();
        _currentLineMatch = this->document()->toPlainText().mid(0, _currentCursorMatch + _findString.length()).count('\n');
    } else {
        _currentCursorMatch = -1;
        _currentLineMatch = -1;
    }
}

int SearchSyntaxHighlighter::totalMatches() const
{
    return _matchList.size();
}

int SearchSyntaxHighlighter::activeMatchIndex() const
{
    return _activeMatchIndex;
}

int SearchSyntaxHighlighter::currentCursorMatch() const
{
    return _currentCursorMatch;
}

int SearchSyntaxHighlighter::currentLineMatch() const
{
    return _currentLineMatch;
}
