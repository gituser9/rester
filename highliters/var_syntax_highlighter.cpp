#include "var_syntax_highlighter.h"

VarSyntaxHighlighter::VarSyntaxHighlighter(QQuickTextDocument* parent) : QSyntaxHighlighter{parent}
{
    QTextCharFormat varFormat;
    varFormat.setForeground(Qt::blue);
    varFormat.setFontWeight(QFont::DemiBold);

    HighlightingRule varRule;
    varRule.pattern = QRegularExpression("{{\\s*(.*?)\\s*}}");
    varRule.pattern.optimize();
    varRule.format = varFormat;

    _highlightingRules.append(varRule);
}

void VarSyntaxHighlighter::setDocument(QQuickTextDocument* pDoc)
{
    QSyntaxHighlighter::setDocument(pDoc->textDocument());
}

void VarSyntaxHighlighter::highlightBlock(const QString& text)
{
    if (!_enabled) {
        return;
    }

    for (const HighlightingRule& rule : std::as_const(_highlightingRules)) {
        QRegularExpressionMatchIterator matchIterator = rule.pattern.globalMatch(text);

        while (matchIterator.hasNext()) {
            QRegularExpressionMatch match = matchIterator.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}

bool VarSyntaxHighlighter::enabled() const
{
    return _enabled;
}

void VarSyntaxHighlighter::setEnabled(bool newEnabled)
{
    if (_enabled == newEnabled) {
        return;
    }

    _enabled = newEnabled;

    rehighlight();
    emit enabledChanged();
}
