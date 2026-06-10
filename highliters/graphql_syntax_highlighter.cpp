#include "graphql_syntax_highlighter.h"

GraphqlSyntaxHighlighter::GraphqlSyntaxHighlighter(QQuickTextDocument* parent) : QSyntaxHighlighter{parent}
{
    // Base Layer
    HighlightingRule identifierRule;
    identifierFormat.setForeground(Qt::blue);
    identifierRule.pattern = QRegularExpression(R"(\b[A-Za-z_]\w*\b)");
    identifierRule.pattern.optimize();
    identifierRule.format = identifierFormat;
    highlightingRules.append(identifierRule);

    // Comments
    HighlightingRule commentRule;
    commentFormat.setForeground(Qt::gray);
    commentFormat.setFontItalic(true);
    commentRule.pattern = QRegularExpression("#[^\n]*");
    commentRule.pattern.optimize();
    commentRule.format = commentFormat;
    highlightingRules.append(commentRule);

    // Strings
    HighlightingRule stringRule;
    stringFormat.setForeground(Qt::darkGreen);
    stringRule.pattern = QRegularExpression(R"("""[\s\S]*?"""|"(?:[^"\\]|\\.)*")");
    stringRule.pattern.optimize();
    stringRule.format = stringFormat;
    highlightingRules.append(stringRule);

    // Variables
    HighlightingRule varRule;
    variableFormat.setForeground(Qt::darkCyan);
    variableFormat.setFontWeight(550);
    varRule.pattern = QRegularExpression(R"(\$\w+)");
    varRule.pattern.optimize();
    varRule.format = variableFormat;
    highlightingRules.append(varRule);

    // Directives
    HighlightingRule directiveRule;
    directiveFormat.setForeground(Qt::darkMagenta);
    directiveRule.pattern = QRegularExpression(R"(@\w+)");
    directiveRule.pattern.optimize();
    directiveRule.format = directiveFormat;
    highlightingRules.append(directiveRule);

    // Keywords
    HighlightingRule keywordRule;
    keywordFormat.setForeground(Qt::darkBlue);
    keywordFormat.setFontWeight(QFont::Bold);
    keywordRule.pattern = QRegularExpression(R"(\b(query|mutation|subscription|fragment|on)\b)");
    keywordRule.pattern.optimize();
    keywordRule.format = keywordFormat;
    highlightingRules.append(keywordRule);

    // Argument Names
    HighlightingRule argRule;
    argumentFormat.setForeground(Qt::darkMagenta);
    argumentFormat.setFontWeight(550);
    argRule.pattern = QRegularExpression(R"(\b[A-Za-z_]\w*(?=\s*:))");
    argRule.pattern.optimize();
    argRule.format = argumentFormat;
    highlightingRules.append(argRule);

    // Boolean and Null
    HighlightingRule boolNullRule;
    booleanNullFormat.setForeground(Qt::darkRed);
    boolNullRule.pattern = QRegularExpression(R"(\b(true|false|null)\b)");
    boolNullRule.pattern.optimize();
    boolNullRule.format = booleanNullFormat;
    highlightingRules.append(boolNullRule);

    // Numbers
    HighlightingRule numRule;
    numberFormat.setForeground(Qt::darkRed);
    numRule.pattern = QRegularExpression(R"(\b\d+(\.\d+)?\b)");
    numRule.pattern.optimize();
    numRule.format = numberFormat;
    highlightingRules.append(numRule);

    // Punctuation
    HighlightingRule punctRule;
    punctuationFormat.setForeground(Qt::black);
    punctuationFormat.setFontWeight(QFont::Bold);
    punctRule.pattern = QRegularExpression(R"([{}()\[\]:=])");
    punctRule.pattern.optimize();
    punctRule.format = punctuationFormat;
    highlightingRules.append(punctRule);
}

void GraphqlSyntaxHighlighter::setDocument(QQuickTextDocument* pDoc)
{
    QSyntaxHighlighter::setDocument(pDoc->textDocument());
}

void GraphqlSyntaxHighlighter::highlightBlock(const QString& text)
{
    for (const HighlightingRule& rule : highlightingRules) {
        QRegularExpressionMatchIterator matchIterator = rule.pattern.globalMatch(text);

        while (matchIterator.hasNext()) {
            QRegularExpressionMatch match = matchIterator.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}
