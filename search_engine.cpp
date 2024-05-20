#include "search_engine.h"


SearchEngine::SearchEngine(QObject *parent) : QObject{parent}
{
    _syntaxHighlighter = std::make_unique<SearchSyntaxHighlighter>();

    connect(this, &SearchEngine::searchStringChanged, this, [this](){
        _syntaxHighlighter->setWordPattern(_searchString);
        highlightText();
    }, Qt::DirectConnection);

    connect(this, &SearchEngine::contentStringChanged, this, [this](){
        highlightText();
    }, Qt::DirectConnection);

    connect(this, &SearchEngine::onPrevHighlightChanged, this, [this](){
        goToPrevHighlight();
    }, Qt::DirectConnection);

    connect(this, &SearchEngine::onNextHighlightChanged, this, [this](){
        goToNextHighlight();
    }, Qt::DirectConnection);
}

SearchEngine::~SearchEngine()
{
    //
}

QObject* SearchEngine::textDocumentObj() const
{
    return qobject_cast<QObject*>(_textDocument);
}

void SearchEngine::setTextDocument(QObject* obj)
{
    if (auto quickTextDocument = qobject_cast<QQuickTextDocument*>(obj)) {
        initializeHighlighter(quickTextDocument->textDocument());
    }
}

void SearchEngine::initializeHighlighter(QTextDocument* textDocument)
{
    if (_textDocument != textDocument) {
        _textDocument = textDocument;

        if (_textDocument) {
            _syntaxHighlighter->setDocument(_textDocument);
        }

        emit onTextDocumentChanged();
    }
}

QTextDocument* SearchEngine::textDocument() const
{
    return _textDocument;
}

QString SearchEngine::searchString() const
{
    return _searchString;
}

void SearchEngine::setSearchString(QString searchString)
{
    if (_searchString != searchString) {
        _searchString = searchString;

        emit searchStringChanged();
    }

    if (searchString.isEmpty()) {
        emit noSearch();
    }
}

QString SearchEngine::contentString() const
{
    return _contentString;
}

void SearchEngine::setContentString(QString contentString)
{
    if (_contentString != contentString) {
        _contentString = contentString;

        emit contentStringChanged();
    }
}

int SearchEngine::highlightIndex() const
{
    return _size > 0 ? _highlightIndex : 0;
}

void SearchEngine::setHighlightIndex(int highlightIndex)
{
    if(_highlightIndex != highlightIndex){
        _highlightIndex = highlightIndex;

        goToHighlightIndex(highlightIndex);

        emit onHighlightIndexChanged();
    }
}

int SearchEngine::size() const
{
    return _size;
}

void SearchEngine::setSize(int size)
{
    if (_size != size) {
        _size = size;

        emit onSizeChanged();
    }
}

void SearchEngine::highlightText()
{
    if (!_textDocument) {
        return;

    }

    _syntaxHighlighter->customRehighlight();

    setSize(_syntaxHighlighter->totalMatches());

    if (_syntaxHighlighter->activeMatchIndex() < _size) {
        if (_size > 0) {
            _syntaxHighlighter->setActiveMatchIndex(_syntaxHighlighter->activeMatchIndex());
        } else {
            _syntaxHighlighter->setActiveMatchIndex(0);
        }
    } else {
        _syntaxHighlighter->setActiveMatchIndex(std::max(_size - 1, 0));
    }

    updateCursorPosition(_syntaxHighlighter->currentCursorMatch());
}

void SearchEngine::updateCursorPosition(int cursorPosition)
{
    setCursorPosition(cursorPosition);

    if (cursorPosition > 0) {
        setHighlightIndex(_syntaxHighlighter->activeMatchIndex() + 1);
    }
}

void SearchEngine::goToNextHighlight()
{
    _syntaxHighlighter->setNextMatchStateActive();

    updateCursorPosition(_syntaxHighlighter->currentCursorMatch());
}

void SearchEngine::goToPrevHighlight()
{
    _syntaxHighlighter->setPrevMatchStateActive();

    updateCursorPosition(_syntaxHighlighter->currentCursorMatch());
}

void SearchEngine::goToHighlightIndex(int index)
{
    _syntaxHighlighter->setActiveMatchIndex(index - 1);

    updateCursorPosition(_syntaxHighlighter->currentCursorMatch());
}

int SearchEngine::cursorPosition() const
{
    return _cursorPosition;
}

void SearchEngine::setCursorPosition(int cursorPosition)
{
    if (_cursorPosition != cursorPosition) {
        _cursorPosition = cursorPosition;

        emit onCursorPositionChanged();
    }
}
