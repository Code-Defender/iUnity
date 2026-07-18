importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js");

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyB0rGADaotanqQ4IaudU7_VO430JVQ_4f4",
  authDomain: "iunity-app-69332.firebaseapp.com",
  projectId: "iunity-app-69332",
  storageBucket: "iunity-app-69332.firebasestorage.app",
  messagingSenderId: "805297169916",
  appId: "1:805297169916:web:1aa9eee60a2f751cad3e79"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title || 'iUnity Signal';
  const notificationOptions = {
    body: payload.notification.body || 'New community message received.',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
