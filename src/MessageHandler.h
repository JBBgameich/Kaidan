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

#ifndef MESSAGEHANDLER_H
#define MESSAGEHANDLER_H

// Qt
#include <QObject>
// QXmpp
#include <QXmppGlobal.h>
#include <QXmppMessage.h>
#include <QXmppMessageReceiptManager.h>
// Kaidan
#include "Enums.h"

class Kaidan;
class MessageModel;
class QMimeType;
class QXmppDiscoveryIq;
#if QXMPP_VERSION >= 0x000904
class QXmppCarbonManager;
#endif

using namespace Enums;

/**
 * @class MessageHandler Handler for incoming and outgoing messages
 */
class MessageHandler : public QObject
{
	Q_OBJECT

public:
	MessageHandler(Kaidan *kaidan, QXmppClient *client, MessageModel *model,
	               QObject *parent = nullptr);

	~MessageHandler();

public slots:
	/**
	 * Handles incoming messages from the server
	 */
	void handleMessage(const QXmppMessage &msg);

	/**
	 * Sends a new message to the server and inserts it into the database
	 */
	void sendMessage(QString toJid, QString body, bool isSpoiler, QString spoilerHint);

	/**
	 * Sends the corrected version of a message
	 */
	void correctMessage(QString toJid, QString msgId, QString newBody);

	/**
	 * Handles service discovery info and enables carbons if feature was found
	 */
	void handleDiscoInfo(const QXmppDiscoveryIq &);

private:
	Kaidan *kaidan;
	QXmppClient *client;
	QXmppMessageReceiptManager receiptManager;
	MessageModel *model;
#if QXMPP_VERSION >= 0x000904
	QXmppCarbonManager *carbonManager;
#endif
	QString chatPartner;
};

#endif // MESSAGEHANDLER_H
