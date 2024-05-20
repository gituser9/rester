#include "var_syntax_highlighter.h"

VarSyntaxHighlighter::VarSyntaxHighlighter(QQuickTextDocument *parent) : QSyntaxHighlighter{parent}
{
    HighlightingRule varRule;
    varFormat.setForeground(Qt::blue);
    varFormat.setFontWeight(QFont::DemiBold);
    varRule.pattern = QRegularExpression("{{\\s*(.*?)\\s*}}");
    varRule.pattern.optimize();
    varRule.format = varFormat;
    highlightingRules.append(varRule);
}

void VarSyntaxHighlighter::setDocument(QQuickTextDocument *pDoc)
{
    QSyntaxHighlighter::setDocument(pDoc->textDocument());
}

void VarSyntaxHighlighter::highlightBlock(const QString &text)
{
    for (const HighlightingRule &rule : std::as_const(highlightingRules)) {
        QRegularExpressionMatchIterator matchIterator = rule.pattern.globalMatch(text);

        while (matchIterator.hasNext()) {
            QRegularExpressionMatch match = matchIterator.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}
