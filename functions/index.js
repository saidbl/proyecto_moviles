const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

// Inicializamos la app de administrador para poder leer la BD y enviar mensajes
admin.initializeApp();

/**
 * Función: sendPushNotification
 * Disparador: Se activa cuando se CREA (.onCreate) un documento
 * en la ruta 'notifications/{notificationId}'
 */
exports.sendPushNotification = functions.firestore
  .document("notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    
    // 1. Obtener los datos de la notificación recién creada
    const notificationData = snap.data();
    const userId = notificationData.userId; // ¿A quién va dirigida?
    const title = notificationData.title || "Nueva notificación";
    const body = notificationData.body || "Tienes un nuevo mensaje en la app";

    // Si no hay userId, no podemos hacer nada
    if (!userId) {
      console.log("No userId found in notification");
      return null;
    }

    try {
      // 2. Buscar el token del usuario en la colección 'users'
      const userDoc = await admin.firestore().collection("users").doc(userId).get();

      // Si el usuario no existe o no tiene token, cancelamos
      if (!userDoc.exists) {
        console.log(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`User ${userId} does not have an FCM token`);
        return null;
      }

      // 3. Crear el mensaje para enviar
      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        // Opcional: Datos extra para manejar clics (abrir pantalla específica)
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          route: "notifications", // Podrías usar esto en Flutter para redirigir
        },
      };

      // 4. Enviar la notificación a través de FCM
      const response = await admin.messaging().send(message);
      console.log("Successfully sent message:", response);
      return response;

    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  });