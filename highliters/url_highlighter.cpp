#include "url_highlighter.h"

UrlHighlighter::UrlHighlighter(QQuickTextDocument* parent) : QSyntaxHighlighter(parent)
{
    // scheme
    schemeFormat.setForeground(QColor("#3399ff"));
    HighlightingRule schemeRule;
    schemeRule.pattern = QRegularExpression(R"([a-zA-Z][a-zA-Z0-9+.-]*(?=://))");
    schemeRule.pattern.optimize();
    schemeRule.format = schemeFormat;
    highlightingRules.append(schemeRule);

    // path
    pathFormat.setForeground(QColor("#cc33cc"));
    HighlightingRule pathRule;
    pathRule.pattern = QRegularExpression(R"(/[^?#]*)");
    pathRule.pattern.optimize();
    pathRule.format = pathFormat;
    highlightingRules.append(pathRule);

    // host
    hostFormat.setForeground(QColor("#33aa33"));
    HighlightingRule hostRule;
    hostRule.pattern = QRegularExpression(R"((?<=://)[^/?#:]+)");
    hostRule.pattern.optimize();
    hostRule.format = hostFormat;
    highlightingRules.append(hostRule);

    // port
    portFormat.setForeground(QColor("#CC6600"));
    HighlightingRule portRule;
    portRule.pattern = QRegularExpression(R"(:\d+(?=[/?#]|$))");
    portRule.pattern.optimize();
    portRule.format = portFormat;
    highlightingRules.append(portRule);

    // query key
    queryKeyFormat.setForeground(QColor("#00aaaa"));
    HighlightingRule queryKeyRule;
    queryKeyRule.pattern = QRegularExpression(R"((?<=[?&])[^=&#]+)");
    queryKeyRule.pattern.optimize();
    queryKeyRule.format = queryKeyFormat;
    highlightingRules.append(queryKeyRule);

    // query value
    queryValueFormat.setForeground(QColor("#ff4444"));
    HighlightingRule queryValueRule;
    queryValueRule.pattern = QRegularExpression(R"((?<=\=)[^&#]*)");
    queryValueRule.pattern.optimize();
    queryValueRule.format = queryValueFormat;
    highlightingRules.append(queryValueRule);

    // fragment (after '#')
    fragmentFormat.setForeground(QColor("#aaaaaa"));
    HighlightingRule fragmentRule;
    fragmentRule.pattern = QRegularExpression(R"(#[^#]*)");
    fragmentRule.pattern.optimize();
    fragmentRule.format = fragmentFormat;
    highlightingRules.append(fragmentRule);

    // delimeters (:// / . ? # & =)
    delimiterFormat.setForeground(QColor("#888888"));
    HighlightingRule delimiterRule;
    delimiterRule.pattern = QRegularExpression(R"(://|[\/.?:#&=])");
    delimiterRule.pattern.optimize();
    delimiterRule.format = delimiterFormat;
    highlightingRules.append(delimiterRule);
}

void UrlHighlighter::setDocument(QQuickTextDocument* pDoc)
{
    QSyntaxHighlighter::setDocument(pDoc->textDocument());
}

void UrlHighlighter::highlightBlock(const QString& text)
{
    for (const HighlightingRule& rule : highlightingRules) {
        QRegularExpressionMatchIterator matchIterator = rule.pattern.globalMatch(text);

        while (matchIterator.hasNext()) {
            QRegularExpressionMatch match = matchIterator.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}
