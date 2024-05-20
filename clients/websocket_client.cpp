#include "websocket_client.h"

WebsocketClient::WebsocketClient(QObject* parent)
    : QObject { parent }
{
    _varRegex = QRegularExpression("{{\\s*(.*?)\\s*}}");
    _varRegex.optimize();

    _socket = std::make_unique<QWebSocket>();

    connect(_socket.get(), &QWebSocket::connected, this, &WebsocketClient::connectedSlot);
    connect(_socket.get(), &QWebSocket::disconnected, this, &WebsocketClient::disconnectedSlot);
    connect(_socket.get(), &QWebSocket::textMessageReceived, this, &WebsocketClient::receivedMsg);
    connect(_socket.get(), &QWebSocket::errorOccurred, this, &WebsocketClient::error);
}

WebsocketClient::~WebsocketClient()
{
    close();
}

void WebsocketClient::open(const QString& url, QVariantList vars) noexcept
{
    QString urlString = url;

    // TODO: duplicate
    if (!vars.isEmpty()) {
        QRegularExpressionMatchIterator iter = _varRegex.globalMatch(urlString);

        while (iter.hasNext()) {
            QRegularExpressionMatch match = iter.next();
            QString variable = match.captured(1).trimmed();

            for (QVariant& var : vars) {
                QVariantMap varMap = var.toMap();

                if (varMap["name"] == variable) {
                    urlString = urlString.replace("{{" + variable + "}}", varMap["value"].toString());
                }
            }
        }
    }

    QUrl socketUrl = urlString;

    _socket->open(socketUrl);
}

void WebsocketClient::send(const QString& msg) noexcept
{
    _socket->sendTextMessage(msg);
}

void WebsocketClient::close() noexcept
{
    if (isConnected) {
        _socket->close();
    }
}

QString WebsocketClient::errorString(QAbstractSocket::SocketError err) const noexcept
{
    switch (err) {
    case QAbstractSocket::SocketError::ConnectionRefusedError:
        return "Connection Refused Error";
    case QAbstractSocket::SocketError::RemoteHostClosedError:
        return "Remote Host Closed Error";
    case QAbstractSocket::SocketError::HostNotFoundError:
        return "Host Not Found Error";
    case QAbstractSocket::SocketError::SocketAccessError:
        return "Socket Access Error";
    case QAbstractSocket::SocketError::SocketResourceError:
        return "Socket Resource Error";
    case QAbstractSocket::SocketError::SocketTimeoutError:
        return "Socket Timeout Error";
    case QAbstractSocket::SocketError::DatagramTooLargeError:
        return "Datagram Too Large Error";
    case QAbstractSocket::SocketError::NetworkError:
        return "Network Error";
    case QAbstractSocket::SocketError::AddressInUseError:
        return "Address In Use Error";
    case QAbstractSocket::SocketError::SocketAddressNotAvailableError:
        return "Socket Address Not Available Error";
    case QAbstractSocket::SocketError::UnsupportedSocketOperationError:
        return "Unsupported Socket Operation Error";
    case QAbstractSocket::SocketError::UnfinishedSocketOperationError:
        return "Unfinished Socket Operation Error";
    case QAbstractSocket::SocketError::ProxyAuthenticationRequiredError:
        return "Proxy Authentication Required Error";
    case QAbstractSocket::SocketError::SslHandshakeFailedError:
        return "Ssl Handshake Failed Error";
    case QAbstractSocket::SocketError::ProxyConnectionRefusedError:
        return "Proxy Connection Refused Error";
    case QAbstractSocket::SocketError::ProxyConnectionClosedError:
        return "Proxy Connection Closed Error";
    case QAbstractSocket::SocketError::ProxyConnectionTimeoutError:
        return "Proxy Connection Timeout Error";
    case QAbstractSocket::SocketError::ProxyNotFoundError:
        return "Proxy Not Found Error";
    case QAbstractSocket::SocketError::ProxyProtocolError:
        return "Proxy Protocol Error";
    case QAbstractSocket::SocketError::OperationError:
        return "Operation Error";
    case QAbstractSocket::SocketError::SslInternalError:
        return "Ssl Internal Error";
    case QAbstractSocket::SocketError::SslInvalidUserDataError:
        return "Ssl Invalid User Data Error";
    case QAbstractSocket::SocketError::TemporaryError:
        return "Temporary Error";

    default:
        return "Unknown Error";
    }
}

void WebsocketClient::connectedSlot()
{
    isConnected = true;

    emit connected();
}

void WebsocketClient::disconnectedSlot()
{
    close();

    isConnected = false;

    emit disconnected();
}

void WebsocketClient::receivedMsg(const QString& msg) noexcept
{
    emit received(msg);
}

void WebsocketClient::error(QAbstractSocket::SocketError err) noexcept
{
    QString msg = errorString(err);

    emit receivedError(msg);
}
