/*
 *  Kaidan - A user-friendly XMPP client for every device!
 *
 *  Copyright (C) 2016-2019 Kaidan developers and contributors
 *  (see the LICENSE file for a full list of copyright authors)
 *
 *  Kaidan is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  In addition, as a special exception, the author of Kaidan gives
 *  permission to link the code of its release with the OpenSSL
 *  project's "OpenSSL" library (or with modified versions of it that
 *  use the same license as the "OpenSSL" library), and distribute the
 *  linked executables. You must obey the GNU General Public License in
 *  all respects for all of the code used other than "OpenSSL". If you
 *  modify this file, you may extend this exception to your version of
 *  the file, but you are not obligated to do so.  If you do not wish to
 *  do so, delete this exception statement from your version.
 *
 *  Kaidan is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Kaidan.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "ClientWorker.h"
// Qt
#include <QDebug>
#include <QSettings>
#include <QGuiApplication>
#include <QSysInfo>
// QXmpp
#include <QXmppClient.h>
#include <QXmppConfiguration.h>
#include <QXmppPresence.h>
#include <QXmppVersionManager.h>
// Kaidan
#include "Kaidan.h"
#include "LogHandler.h"
#include "RosterManager.h"
#include "MessageHandler.h"
#include "DiscoveryManager.h"
#include "VCardManager.h"
#include "UploadManager.h"
#include "DownloadManager.h"

ClientWorker::ClientWorker(Caches *caches, Kaidan *kaidan, bool enableLogging, QGuiApplication *app,
                           QObject* parent)
	: QObject(parent), caches(caches), kaidan(kaidan), enableLogging(enableLogging), app(app)
{
	client = new QXmppClient(this);
	logger = new LogHandler(client, this);
	logger->enableLogging(enableLogging);
	vCardManager = new VCardManager(client, caches->avatarStorage, this);
	rosterManager = new RosterManager(kaidan, client,  caches->rosterModel,
	                                  caches->avatarStorage, vCardManager, this);
	msgHandler = new MessageHandler(kaidan, client, caches->msgModel, this);
	discoManager = new DiscoveryManager(client, this);
	uploadManager = new UploadManager(kaidan, client, caches->msgModel, rosterManager,
	                                  caches->transferCache, this);
	downloadManager = new DownloadManager(kaidan, caches->transferCache,
	                                      caches->msgModel, this);

	connect(client, &QXmppClient::presenceReceived,
	        caches->presCache, &PresenceCache::updatePresenceRequested);

	connect(this, &ClientWorker::credentialsUpdated, this, &ClientWorker::setCredentials);

	// publish kaidan version
	client->versionManager().setClientName(APPLICATION_DISPLAY_NAME);
	client->versionManager().setClientVersion(VERSION_STRING);
	client->versionManager().setClientOs(QSysInfo::prettyProductName());

#if QXMPP_VERSION >= 0x000904
	// Client State Indication
	connect(app, &QGuiApplication::applicationStateChanged, this, &ClientWorker::setCsiState);
#endif
}

ClientWorker::~ClientWorker()
{
	delete client;
	delete logger;
	delete rosterManager;
	delete msgHandler;
	delete discoManager;
	delete vCardManager;
	delete uploadManager;
	delete downloadManager;
}

void ClientWorker::main()
{
	// initialize random generator
	qsrand(time(nullptr));

	connect(client, &QXmppClient::stateChanged, kaidan, &Kaidan::setConnectionState);
	connect(client, &QXmppClient::connected, this, &ClientWorker::onConnect);
	connect(client, &QXmppClient::error, this, &ClientWorker::onConnectionError);

	connect(this, &ClientWorker::connectRequested, this, &ClientWorker::xmppConnect);
	connect(this, &ClientWorker::disconnectRequested, client, &QXmppClient::disconnectFromServer);
}

void ClientWorker::xmppConnect()
{
	QXmppConfiguration config;
	config.setJid(creds.jid);
	config.setResource(creds.jidResource.append(".").append(generateRandomString()));
	config.setPassword(creds.password);
	config.setAutoAcceptSubscriptions(false);
	config.setStreamSecurityMode(QXmppConfiguration::TLSRequired);
	config.setAutoReconnectionEnabled(true); // will automatically reconnect
	// on first try we must be sure that we connect successfully
	// otherwise this could end in a reconnection loop
	if (creds.isFirstTry)
		config.setAutoReconnectionEnabled(false);

	client->connectToServer(config, QXmppPresence(QXmppPresence::Available));
}

void ClientWorker::onConnect()
{
	// no mutex needed, because this is called from updateClient()
	qDebug() << "[client] Connected successfully to server";

	// Emit signal, that logging in with these credentials has worked for the first time
	if (creds.isFirstTry)
		emit kaidan->logInWorked();

	// accept credentials and save them
	creds.isFirstTry = false;
	caches->settings->setValue("auth/jid", creds.jid);
	caches->settings->setValue("auth/password",
	                           QString::fromUtf8(creds.password.toUtf8().toBase64()));

	// after first log in we always want to automatically reconnect
	client->configuration().setAutoReconnectionEnabled(true);
}

void ClientWorker::onConnectionError(QXmppClient::Error error)
{
	// no mutex needed, because this is called from updateClient()
	qDebug() << "[client] Disconnected:" << error;

	// Check if first time connecting with these credentials
	if (creds.isFirstTry || error == QXmppClient::XmppStreamError) {
		// always request new credentials, when failed to connect on first time
		emit kaidan->newCredentialsNeeded();
	}

	if (error == QXmppClient::NoError) {
		emit disconnReasonChanged(DisconnReason::ConnUserDisconnected);
	} else if (error == QXmppClient::KeepAliveError) {
		emit disconnReasonChanged(DisconnReason::ConnKeepAliveError);
	} else if (error == QXmppClient::XmppStreamError) {
		QXmppStanza::Error::Condition xError = client->xmppStreamError();
		qDebug() << xError;
		if (xError == QXmppStanza::Error::NotAuthorized) {
			emit disconnReasonChanged(DisconnReason::ConnAuthenticationFailed);
		} else {
			emit disconnReasonChanged(DisconnReason::ConnNotConnected);
		}
	} else if (error == QXmppClient::SocketError) {
		QAbstractSocket::SocketError sError = client->socketError();
		if (sError == QAbstractSocket::ConnectionRefusedError ||
		    sError == QAbstractSocket::RemoteHostClosedError) {
			emit disconnReasonChanged(DisconnReason::ConnConnectionRefused);
		} else if (sError == QAbstractSocket::HostNotFoundError) {
			emit disconnReasonChanged(DisconnReason::ConnDnsError);
		} else if (sError == QAbstractSocket::SocketAccessError) {
			emit disconnReasonChanged(DisconnReason::ConnNoNetworkPermission);
		} else if (sError == QAbstractSocket::SocketTimeoutError) {
			emit disconnReasonChanged(DisconnReason::ConnKeepAliveError);
		} else if (sError == QAbstractSocket::SslHandshakeFailedError ||
		           sError == QAbstractSocket::SslInternalError) {
			emit disconnReasonChanged(DisconnReason::ConnTlsFailed);
		} else {
			emit disconnReasonChanged(DisconnReason::ConnNotConnected);
		}
	}
}

QString ClientWorker::generateRandomString(unsigned int length) const
{
	const QString possibleCharacters("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklm"
	                                 "nopqrstuvwxyz0123456789");
	const int numOfChars = possibleCharacters.length();

	QString randomString;
	for (unsigned int i = 0; i < length; ++i) {
		int index = qrand() % numOfChars;
		QChar nextChar = possibleCharacters.at(index);
		randomString.append(nextChar);
	}
	return randomString;
}

#if QXMPP_VERSION >= 0x000904 // after QXmpp v0.9.4
void ClientWorker::setCsiState(Qt::ApplicationState state)
{
	if (state == Qt::ApplicationActive)
		client->setActive(true);
	else
		client->setActive(false);
}
#endif
