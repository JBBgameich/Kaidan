/*
 *  Kaidan - A user-friendly XMPP client for every device!
 *
 *  Copyright (C) 2017 LNJ <git@lnj.li>
 *
 *  Kaidan is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Kaidan is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Kaidan. If not, see <http://www.gnu.org/licenses/>.
 */

// Kaidan
#include "MessageModel.h"
// C++
#include <iostream>
// Qt 5
#include <QDateTime>
#include <QDebug>
#include <QSqlError>
#include <QSqlRecord>
#include <QSqlQuery>

static const char *conversationsTableName = "Messages";

static void createTable()
{
	if (QSqlDatabase::database().tables().contains(conversationsTableName)) {
		// The table already exists; we don't need to do anything.
		return;
	}

	QSqlQuery query;
	if (!query.exec(
		"CREATE TABLE IF NOT EXISTS 'Messages' ("
		"'author' TEXT NOT NULL,"
		"'author_resource' TEXT,"
		"'recipient' TEXT NOT NULL,"
		"'recipient_resource' TEXT,"
		"'timestamp' TEXT NOT NULL,"
		"'message' TEXT NOT NULL,"
		"'id' TEXT NOT NULL,"
		"'isSent' BOOL,"
		"'isDelivered' BOOL,"
		"'isRead' BOOL,"
		"'meta' TEXT," // placeholder field for later additons
		"FOREIGN KEY('author') REFERENCES Contacts ('jid'),"
		"FOREIGN KEY('recipient') REFERENCES Contacts ('jid')"
		")"))
	{
		qFatal("Failed to query database: %s", qPrintable(query.lastError().text()));
	}
}

MessageModel::MessageModel(QObject *parent) :
	QSqlTableModel(parent)
{
	createTable();
	setTable(conversationsTableName);

	// sort in descending order of the timestamp column
	setSort(4, Qt::DescendingOrder);

	// Ensures that the model is sorted correctly after submitting a new row.
	setEditStrategy(QSqlTableModel::OnManualSubmit);
}

void MessageModel::applyRecipientFilter(QString recipient_, QString author_)
{
	// DEPRECATED: author/recipient = 'Me'
	const QString filterString = QString::fromLatin1("(recipient = '%1' AND "
		"author = 'Me') OR (recipient = 'Me' AND author='%1') OR "
		"(recipient = '%1' AND author = '%2') OR (recipient = '%2' AND "
		"author = '%1')").arg(recipient_, author_);
	setFilter(filterString);
	select();
}

QVariant MessageModel::data(const QModelIndex &index, int role) const
{
	if (role < Qt::UserRole)
		return QSqlTableModel::data(index, role);

	const QSqlRecord sqlRecord = record(index.row());
	return sqlRecord.value(role - Qt::UserRole);
}

QHash<int, QByteArray> MessageModel::roleNames() const
{
	QHash<int, QByteArray> names;
	names[Qt::UserRole] = "author";
	names[Qt::UserRole + 1] = "author_resource";
	names[Qt::UserRole + 2] = "recipient";
	names[Qt::UserRole + 3] = "recipient_resource";
	names[Qt::UserRole + 4] = "timestamp";
	names[Qt::UserRole + 5] = "message";
	names[Qt::UserRole + 6] = "id";
	names[Qt::UserRole + 7] = "isSent"; // sent to server
	names[Qt::UserRole + 8] = "isDelivered"; // message has arrived on a client
	names[Qt::UserRole + 9] = "isRead"; // message has been read from the recipient
	names[Qt::UserRole + 10] = "meta";
	return names;
}

void MessageModel::setMessageAsSent(const QString msgId)
{
	QSqlQuery newQuery;
	newQuery.exec(QString("UPDATE 'Messages' SET 'isSent' = 1 WHERE id = '%1'").arg(msgId));
	submitAll();
}

void MessageModel::setMessageAsDelivered(const QString msgId)
{
	QSqlQuery newQuery;
	newQuery.exec(QString("UPDATE 'Messages' SET 'isDelivered' = 1 WHERE id = '%1'").arg(msgId));
	submitAll();
}

void MessageModel::setMessageAsRead(const QString msgId)
{
	QSqlQuery newQuery;
	newQuery.exec(QString("UPDATE 'Messages' SET 'isRead' = 1 WHERE id = '%1'").arg(msgId));
	submitAll();
}

void MessageModel::addMessage(const QString* author, const QString* author_resource,
	const QString* recipient, const QString* recipient_resource,
	const QString* timestamp, const QString* message, const QString* msgId,
	bool sentByMe)
{
	//
	// add the new message
	//

	QSqlRecord newRecord = record();
	newRecord.setValue("author", *author);
	newRecord.setValue("author_resource", *author_resource);
	newRecord.setValue("recipient", *recipient);
	newRecord.setValue("recipient_resource", *recipient_resource);
	newRecord.setValue("timestamp", *timestamp);
	newRecord.setValue("message", *message);
	newRecord.setValue("id", *msgId);
	newRecord.setValue("isSent", sentByMe ? false : true);
	newRecord.setValue("isDelivered", sentByMe ? false : true);
	newRecord.setValue("isRead", false);

	if (!insertRecord(rowCount(), newRecord)) {
		qWarning() << "Failed to add message to DB:" << lastError().text();
		return;
	}

	submitAll();
}
