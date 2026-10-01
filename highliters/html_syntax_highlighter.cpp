#include "html_syntax_highlighter.h"

using namespace std;

HtmlSyntaxHighlighter::HtmlSyntaxHighlighter(QQuickTextDocument* parent) : QSyntaxHighlighter{parent}
{
    // Tags
    HighlightingRule tagRule;
    tagFormat.setForeground(Qt::red);
    tagRule.pattern = QRegularExpression("<([^\\s>]+)(\\s|>)+");
    tagRule.pattern.optimize();
    tagRule.format = tagFormat;
    highlightingRules.append(tagRule);

    // Attribute names
    HighlightingRule attributeRule;
    attributeFormat.setForeground(Qt::darkMagenta);
    attributeRule.pattern = QRegularExpression("\\w+(?:-\\w+)*(?=\\s*=\\s*[\"'])");
    attributeRule.pattern.optimize();
    attributeRule.format = attributeFormat;
    highlightingRules.append(attributeRule);

    // Attribute values
    HighlightingRule attributeValueRule;
    attributeValueFormat.setForeground(Qt::darkGreen);
    attributeValueRule.pattern = QRegularExpression("\\s*=\\s*[\"']([^\"']*)[\"']");
    attributeValueRule.pattern.optimize();
    attributeValueRule.format = attributeValueFormat;
    highlightingRules.append(attributeValueRule);

    // HighlightingRule valueRule;
    // valueFormat.setForeground(Qt::black);
    // valueRule.pattern = QRegularExpression("([\"'])(?:(?=(\\\\?))\\2.)*?\\1");
    // valueRule.format = valueFormat;
    // highlightingRules.append(valueRule);

    // Vars
    HighlightingRule varRule;
    varFormat.setForeground(Qt::blue);
    varFormat.setFontWeight(QFont::DemiBold);
    varRule.pattern = QRegularExpression(RstConstant::varRegexPattern);
    varRule.pattern.optimize();
    varRule.format = varFormat;
    highlightingRules.append(varRule);
}

void HtmlSyntaxHighlighter::setDocument(QQuickTextDocument* pDoc)
{
    QSyntaxHighlighter::setDocument(pDoc->textDocument());
}

void HtmlSyntaxHighlighter::highlightBlock(const QString& text)
{
    for (const HighlightingRule& rule : std::as_const(highlightingRules)) {
        QRegularExpressionMatchIterator matchIterator = rule.pattern.globalMatch(text);

        while (matchIterator.hasNext()) {
            QRegularExpressionMatch match = matchIterator.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}
