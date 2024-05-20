#include "json_syntax_highlighter.h"

JsonSyntaxHighlighter::JsonSyntaxHighlighter(QQuickTextDocument *parent) : QSyntaxHighlighter{parent}
{
    // JSON keywords
    keywordFormat.setForeground(Qt::darkBlue);

    const QStringList keywords = {
        QStringLiteral("\\bnull\\b"),
        QStringLiteral("\\btrue\\b"),
        QStringLiteral("\\bfalse\\b")
    };
    HighlightingRule keywordRule;

    for (const QString &pattern : keywords) {
        keywordRule.pattern = QRegularExpression(pattern);
        keywordRule.pattern.optimize();
        keywordRule.format = keywordFormat;
        highlightingRules.append(keywordRule);
    }

    // Strings (field names)
    HighlightingRule stringFieldRule;
    fieldNameFormat.setForeground(Qt::darkMagenta);
    fieldNameFormat.setFontWeight(550);
    stringFieldRule.pattern = QRegularExpression("\"\\w+\":");
    stringFieldRule.pattern.optimize();
    stringFieldRule.format = fieldNameFormat;
    highlightingRules.append(stringFieldRule);

    // Numbers
    HighlightingRule numRule;
    numberFormat.setForeground(Qt::darkRed);
    numRule.pattern = QRegularExpression("\\b\\d+(\\.\\d+)?\\b");
    numRule.pattern.optimize();
    numRule.format = numberFormat;
    highlightingRules.append(numRule);

    // Strings (field values)
    HighlightingRule stringValueRule;
    fieldValueFormat.setForeground(Qt::darkGreen);
    stringValueRule.pattern = QRegularExpression(":\\s*\"([^\"]*)\"");
    stringValueRule.pattern.optimize();
    stringValueRule.format = fieldValueFormat;
    highlightingRules.append(stringValueRule);

    HighlightingRule arrRule;
    arrayFormat.setForeground(Qt::black);
    arrRule.pattern = QRegularExpression("[\\[\\]]");
    arrRule.pattern.optimize();
    arrRule.format = arrayFormat;
    highlightingRules.append(arrRule);

    // Objects
    HighlightingRule objRule;
    objectFormat.setForeground(Qt::black);
    objRule.pattern = QRegularExpression("[\\{\\}]");
    objRule.pattern.optimize();
    objRule.format = objectFormat;
    highlightingRules.append(objRule);

    // Tabs or spaces for indentation ??
    HighlightingRule identRule;
    indentationFormat.setForeground(Qt::lightGray);
    identRule.pattern = QRegularExpression("^[\t ]+");
    identRule.pattern.optimize();
    identRule.format = indentationFormat;
    highlightingRules.append(identRule);
}

void JsonSyntaxHighlighter::setDocument(QQuickTextDocument *pDoc)
{
    QSyntaxHighlighter::setDocument(pDoc->textDocument());
}

void JsonSyntaxHighlighter::highlightBlock(const QString &text)
{
    for (const HighlightingRule &rule : highlightingRules) {
        QRegularExpressionMatchIterator matchIterator = rule.pattern.globalMatch(text);

        while (matchIterator.hasNext()) {
            QRegularExpressionMatch match = matchIterator.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}
