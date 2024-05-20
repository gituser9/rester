#ifndef SEARCHENGINE_H
#define SEARCHENGINE_H

#include <memory>

#include <QString>
#include <QTextDocument>
#include <QTextCursor>
#include <QQuickTextDocument>

#include "highliters/search_syntax_highlighter.h"


class SearchEngine : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString searchString READ searchString WRITE setSearchString NOTIFY searchStringChanged)
    Q_PROPERTY(QString contentString READ contentString WRITE setContentString NOTIFY contentStringChanged)
    Q_PROPERTY(int highlightIndex READ highlightIndex WRITE setHighlightIndex NOTIFY onHighlightIndexChanged)
    Q_PROPERTY(int size READ size WRITE setSize NOTIFY onSizeChanged)
    Q_PROPERTY(int cursorPosition READ cursorPosition WRITE setCursorPosition NOTIFY onCursorPositionChanged)
    Q_PROPERTY(QObject* textDocumentObj READ textDocumentObj WRITE setTextDocument)
    Q_PROPERTY(QTextDocument* textDocument READ textDocument NOTIFY onTextDocumentChanged)


public:
    explicit SearchEngine(QObject *parent = nullptr);
    ~SearchEngine();

    void initializeHighlighter(QTextDocument* textDocument);
    QObject* textDocumentObj() const;
    void setTextDocument(QObject* obj);
    QTextDocument* textDocument() const;

    QString searchString() const;
    void setSearchString(QString searchString);

    QString contentString() const;
    void setContentString(QString contentString);

    int highlightIndex() const;
    void setHighlightIndex(int highlightIndex);

    int size() const;
    void setSize(int size);

    int cursorPosition() const;
    void setCursorPosition(int cursorPosition);


private:
    void highlightText();
    void TextEditRefreshHighlighter();
    void goToPrevHighlight();
    void goToNextHighlight();
    void goToHighlightIndex(int index);
    void updateCursorPosition(int cursorPosition);


signals:
    void searchStringChanged();
    void contentStringChanged();
    void onSizeChanged();
    void onHighlightIndexChanged();
    void onPrevHighlightChanged();
    void onNextHighlightChanged();
    void onCursorPositionChanged();
    void onTextDocumentChanged();
    void noSearch();


private:
    QString _searchString;
    QString _contentString;
    QTextDocument* _textDocument = nullptr;
    int _highlightIndex = 0;
    int _size = 0;
    int _cursorPosition = 0;
    std::unique_ptr<SearchSyntaxHighlighter> _syntaxHighlighter;

};

#endif // SEARCHENGINE_H
