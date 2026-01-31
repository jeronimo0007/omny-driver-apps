// Firebase configuration for web
// This file is loaded in index.html

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCceQTKfoIsPblC4vWMyxC8HfaVUKc0U5U",
  authDomain: "goin-7372e.firebaseapp.com",
  databaseURL: "https://goin-7372e-default-rtdb.firebaseio.com",
  projectId: "goin-7372e",
  storageBucket: "goin-7372e.firebasestorage.app",
  messagingSenderId: "725859983456",
  appId: "1:725859983456:web:7d738c80d0d3e3376c2305",
  measurementId: "G-RX7QR1W5W8"
};

// Initialize Firebase (will be called from index.html)
if (typeof firebase !== 'undefined') {
  firebase.initializeApp(firebaseConfig);
  console.log('🔥 [WEB] Firebase inicializado para web');
}
