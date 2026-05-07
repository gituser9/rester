#ifndef HIGHLIGHTING_RULE_H
#define HIGHLIGHTING_RULE_H

#include <QRegularExpression>
#include <QTextCharFormat>

struct HighlightingRule {
    QRegularExpression pattern;
    QTextCharFormat format;
};

#endif // HIGHLIGHTING_RULE_H
