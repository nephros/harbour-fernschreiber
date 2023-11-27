/*
    Copyright (C) 2020 Sebastian J. Wolf and other contributors

    This file is part of Fernschreiber.

    Fernschreiber is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Fernschreiber is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Fernschreiber. If not, see <http://www.gnu.org/licenses/>.
*/
import QtQuick 2.6
import Sailfish.Silica 1.0
import WerkWolf.Fernschreiber 1.0
import "../components"
import "../js/functions.js" as Functions

CoverBackground {

    id: coverPage

    property int unreadMessages: 0
    property int mutedMessages: 0
    property int unreadChats: 0
    readonly property bool authenticated: tdLibWrapper.authorizationState === TelegramAPI.AuthorizationReady
    property int connectionState: TelegramAPI.WaitingForNetwork

    function setUnreadInfoText() {

        unreadMessagesText.text = qsTr("unread messages", "", coverPage.unreadMessages);
        unreadChatsText.text = qsTr("chats", "", coverPage.unreadChats)
        mutedMessagesText.text = qsTr("messages muted", "", coverPage.mutedMessages);

        switch (coverPage.connectionState) {
        case TelegramAPI.WaitingForNetwork:
            connectionStateText.text = qsTr("Waiting for network...");
            break;
        case TelegramAPI.Connecting:
            connectionStateText.text = qsTr("Connecting to network...");
            break;
        case TelegramAPI.ConnectingToProxy:
            connectionStateText.text = qsTr("Connecting to proxy...");
            break;
        case TelegramAPI.ConnectionReady:
            connectionStateText.text = qsTr("Connected");
            break;
        case TelegramAPI.Updating:
            connectionStateText.text = qsTr("Updating content...");
            break;
        }
    }

    Component.onCompleted: {
        coverPage.connectionState = tdLibWrapper.getConnectionState();
        if (appSettings.showMutedUnread) {
            coverPage.unreadMessages = tdLibWrapper.getUnreadMessageInformation().unread_count || 0;
            coverPage.unreadChats = tdLibWrapper.getUnreadChatInformation().unread_count || 0;
        } else {
            var msgs = tdLibWrapper.getUnreadMessageInformation()
            coverPage.unreadMessages = msgs.unread_unmuted_count || 0;
            coverPage.mutedMessages = msgs.unread_count - msgs.unread_unmuted_count
            coverPage.unreadChats = tdLibWrapper.getUnreadChatInformation().unread_unmuted_count || 0;
        }
        setUnreadInfoText();
    }

    Connections {
        target: tdLibWrapper
        onUnreadMessageCountUpdated: {
            coverPage.unreadMessages = appSettings.showMutedUnread ? messageCountInformation.unread_count : messageCountInformation.unread_unmuted_count;
            coverPage.mutedMessages  = appSettings.showMutedUnread ? (messageCountInformation.unread_count - messageCountInformation.unread_unmuted_count) : 0
            setUnreadInfoText();
        }
        onUnreadChatCountUpdated: {
            coverPage.unreadChats = appSettings.showMutedUnread ? chatCountInformation.unread_count : chatCountInformation.unread_unmuted_count;
            setUnreadInfoText();
        }
        onAuthorizationStateChanged: {
            setUnreadInfoText();
        }
        onConnectionStateChanged: {
            coverPage.connectionState = connectionState;
            setUnreadInfoText();
        }
    }

    /*
    Connections {
        target: chatListModel
        onUnreadStateChanged: {
            coverPage.unreadMessages = unreadMessagesCount;
            coverPage.unreadChats = unreadChatsCount;
            setUnreadInfoText();
        }
    }
    */

    BackgroundImage {
        id: backgroundImage
        width: parent.height - Theme.paddingLarge
        height: width
        sourceDimension: width
        anchors {
            verticalCenter: parent.verticalCenter
            centerIn: undefined
            bottom: parent.bottom
            bottomMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
    }

    Column {
        anchors.top: parent.top
        x: Theme.paddingLarge
        topPadding: Theme.paddingLarge
        width: parent.width - Theme.paddingLarge
        spacing: Theme.paddingMedium
        visible: coverPage.authenticated
        Row {
            width: parent.width
            spacing: Theme.paddingMedium
            Text {
                id: unreadMessagesCountText
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.primaryColor
                text: Functions.getShortenedCount(coverPage.unreadMessages)
            }
            Label {
                id: unreadMessagesText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width - unreadMessagesCountText.width - Theme.paddingMedium
                wrapMode: Text.Wrap
                anchors.verticalCenter: unreadMessagesCountText.verticalCenter
                maximumLineCount: 2
                truncationMode: TruncationMode.Fade
            }
        }

        Row {
            width: parent.width
            spacing: Theme.paddingMedium
            visible: coverPage.authenticated && coverPage.unreadMessages > 1
            Text {
                id: inText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                text: qsTr("in")
                anchors.verticalCenter: unreadChatsCountText.verticalCenter
            }
            Text {
                id: unreadChatsCountText
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.primaryColor
                text: Functions.getShortenedCount(coverPage.unreadChats)
            }
            Text {
                id: unreadChatsText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.primaryColor
                width: parent.width - unreadChatsCountText.width - inText.width - ( 2 * Theme.paddingMedium )
                wrapMode: Text.Wrap
                anchors.verticalCenter: unreadChatsCountText.verticalCenter
            }
        }
    }

    Text {
        id: connectionStateText
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.highlightColor
        visible: coverPage.authenticated
        maximumLineCount: 3
        wrapMode: Text.Wrap
    }

    Column {
        anchors.bottom: parent.bottom
        x: Theme.paddingLarge
        bottomPadding: Theme.paddingLarge
        width: parent.width - Theme.paddingLarge
        spacing: Theme.paddingMedium
        visible: coverPage.authenticated
        Row {
            width: parent.width
            spacing: Theme.paddingMedium
            visible: !appSettings.showMutedUnread
            Text {
                id: mutedMessagesCountText
                font.pixelSize: (coverPage.mutedMessages > 99) ? Theme.fontSizeLarge : Theme.fontSizeExtraLarge
                color: Theme.secondaryColor
                text: Functions.getShortenedCount(coverPage.mutedMessages)
            }
            Label {
                id: mutedMessagesText
                font.pixelSize: Theme.fontSizeExtraSmall
                width: parent.width - mutedMessagesCountText.width - Theme.paddingMedium
                wrapMode: Text.Wrap
                anchors.verticalCenter: mutedMessagesCountText.verticalCenter
                maximumLineCount: 2
                truncationMode: TruncationMode.Fade
                color: Theme.secondaryColor
            }
        }
    }
}
