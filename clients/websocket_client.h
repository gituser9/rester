#ifndef WEBSOCKET_CLIENT_H
#define WEBSOCKET_CLIENT_H

#include <memory>

#include <QUrl>
#include <QWebSocket>

#include "../util.h"

class WebsocketClient : public QObject
{
    Q_OBJECT

public:
    explicit WebsocketClient(QObject* parent = nullptr);
    virtual ~WebsocketClient();

    Q_INVOKABLE void open(const QString& url, const QVariantList& vars) noexcept;
    Q_INVOKABLE void send(const QString& msg) noexcept;
    Q_INVOKABLE void close() noexcept;

signals:
    void connected();
    void disconnected();
    void received(const QString&);
    void receivedError(const QString&);

private:
    std::unique_ptr<QWebSocket> _socket;
    bool isConnected = false;

    QString errorString(QAbstractSocket::SocketError err) const noexcept;

private slots:
    void connectedSlot();
    void disconnectedSlot();
    void receivedMsg(const QString& msg) noexcept;
    void error(QAbstractSocket::SocketError err) noexcept;
};

#endif
