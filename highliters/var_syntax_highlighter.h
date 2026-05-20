#ifndef VARSYNTAXHIGHLIGHTER_H
#define VARSYNTAXHIGHLIGHTER_H

#include <QSyntaxHighlighter>
#include <QQuickTextDocument>

#include "../app_data/highlighting_rule.h"

class VarSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged FINAL)

public:
    explicit VarSyntaxHighlighter(QQuickTextDocument* parent = nullptr);

    Q_INVOKABLE void setDocument(QQuickTextDocument* pDoc);

    // QML
    bool enabled() const;
    void setEnabled(bool newEnabled);

signals:
    void enabledChanged();

protected:
    void highlightBlock(const QString& text) override;

private:
    QList<HighlightingRule> _highlightingRules;
    bool _enabled = true;
};

#endif // VARSYNTAXHIGHLIGHTER_H
