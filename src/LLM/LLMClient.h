#pragma once

#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtNetwork/QNetworkAccessManager>
#include <QtNetwork/QNetworkReply>
#include <QtQmlIntegration/QtQmlIntegration>

class LLMClient : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString apiKey READ apiKey WRITE setApiKey NOTIFY apiKeyChanged)

public:
    explicit LLMClient(QObject *parent = nullptr);

    Q_INVOKABLE void sendMessage(const QString &prompt, const QString &context);

    QString apiKey() const { return _apiKey; }
    void setApiKey(const QString &key);

signals:
    void apiKeyChanged();
    void responseReceived(const QString &response);
    void errorOccurred(const QString &error);

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager *_networkManager;
    QString _apiKey;
};
