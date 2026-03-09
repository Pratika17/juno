const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushNotificationOnNewDoc = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {

    const snap = event.data;
    if (!snap) return null;

    const notificationData = snap.data();
    const recipientId = notificationData.userId;

    if (!recipientId) {
      console.log("No userId found in notification");
      return null;
    }

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(recipientId)
      .get();

    if (!userDoc.exists) {
      console.log("User does not exist!");
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log("User does not have an FCM token saved.");
      return null;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: notificationData.title,
        body: notificationData.body,
      },
      data: {
        type: String(notificationData.type || "general"),
        chatId: String(notificationData.chatId || ""),
        itemId: String(notificationData.itemId || ""),
        senderId: String(notificationData.senderId || ""),
        senderName: String(notificationData.senderName || "")
      },
      android: {
        priority: "high"
      },
      apns: {
        payload: {
          aps: {
            sound: "default"
          }
        }
      }
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log("Successfully sent message:", response);
    } catch (error) {
      console.error("Error sending message:", error);
    }

    return null;
  }
);