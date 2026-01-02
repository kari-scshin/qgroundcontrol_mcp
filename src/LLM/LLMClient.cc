#include "LLMClient.h"
#include <QtCore/QJsonDocument>
#include <QtCore/QJsonObject>
#include <QtCore/QJsonArray>
#include <QtNetwork/QNetworkRequest>

LLMClient::LLMClient(QObject *parent)
    : QObject(parent)
    , _networkManager(new QNetworkAccessManager(this))
{
}

void LLMClient::setApiKey(const QString &key)
{
    if (_apiKey != key) {
        _apiKey = key;
        emit apiKeyChanged();
    }
}

void LLMClient::sendMessage(const QString &prompt, const QString &context)
{
    if (_apiKey.isEmpty()) {
        emit errorOccurred("API Key is missing.");
        return;
    }

    QUrl url("https://api.openai.com/v1/chat/completions");
    QNetworkRequest request(url);

    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Authorization", "Bearer " + _apiKey.toUtf8());

    QJsonObject systemMessage;
    systemMessage["role"] = "system";
    systemMessage["content"] = "You are a helpful assistant for a QGroundControl operator. "
                               "You have access to the following vehicle context:\n" + context;

    QJsonObject userMessage;
    userMessage["role"] = "user";
    userMessage["content"] = prompt;

    QJsonArray messages;
    messages.append(systemMessage);
    messages.append(userMessage);

    QJsonObject json;
    json["model"] = "gpt-3.5-turbo"; // Or gpt-3.5-turbo
    json["messages"] = messages;

    QNetworkReply *reply = _networkManager->post(request, QJsonDocument(json).toJson());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onReplyFinished(reply);
    });
}

void LLMClient::onReplyFinished(QNetworkReply *reply)
{
    reply->deleteLater();

    QByteArray data = reply->readAll(); // Read response body even on error

    if (reply->error() != QNetworkReply::NoError) {
        QString errorMessage = reply->errorString();

        // Try to parse the error message from OpenAI JSON response
        if (!data.isEmpty()) {
            QJsonDocument doc = QJsonDocument::fromJson(data);
            QJsonObject root = doc.object();
            if (root.contains("error")) {
                QJsonObject errorObj = root["error"].toObject();
                if (errorObj.contains("message")) {
                    errorMessage = errorObj["message"].toString();
                }
            }
        }
        emit errorOccurred(errorMessage);
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject root = doc.object();

    if (root.contains("choices")) {
        QJsonArray choices = root["choices"].toArray();
        if (!choices.isEmpty()) {
            QJsonObject firstChoice = choices.first().toObject();
            QJsonObject message = firstChoice["message"].toObject();
            QString content = message["content"].toString();
            emit responseReceived(content);
        } else {
            emit errorOccurred("No choices in response.");
        }
    } else if (root.contains("error")) {
         emit errorOccurred(root["error"].toObject()["message"].toString());
    } else {
        emit errorOccurred("Invalid response format.");
    }
}
