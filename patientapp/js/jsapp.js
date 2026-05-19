import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.0/firebase-app.js";
import { getAuth, signInWithEmailAndPassword, signOut } from "https://www.gstatic.com/firebasejs/11.0.0/firebase-auth.js";

const firebaseConfig = {
  apiKey: "AIzaSyDUyO5dnWqeQkb2bMsOVFRxwDTunhPwi5Q",
  authDomain: "physiotrack-c8d8d.firebaseapp.com",
  projectId: "physiotrack-c8d8d",
  storageBucket: "physiotrack-c8d8d.firebasestorage.app",
  messagingSenderId: "769477876130",
  appId: "1:769477876130:web:4608f1e7554e46c5603afb"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

let selectedPainLevel = null;
let selectedPainLabel = null;

function setGreeting() {
  const hour = new Date().getHours();
  let greet = "Good morning";
  if (hour >= 12 && hour < 17) greet = "Good afternoon";
  else if (hour >= 17) greet = "Good evening";
  const el = document.getElementById("greeting");
  if (el) el.textContent = greet + ", Sarah";
}

async function login() {
  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;
  try {
    await signInWithEmailAndPassword(auth, email, password);
    document.getElementById("loginScreen").style.display = "none";
    document.getElementById("app").style.display = "block";
    setGreeting();
  } catch (error) {
    alert("Login failed: " + error.message);
  }
}

async function logout() {
  await signOut(auth);
  document.getElementById("app").style.display = "none";
  document.getElementById("loginScreen").style.display = "flex";
}

function showSection(sectionId, button) {
  document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
  document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));
  document.getElementById(sectionId).classList.add("active");
  button.classList.add("active");
}

function selectFace(el, level, label) {
  document.querySelectorAll(".face-btn").forEach(b => b.classList.remove("active"));
  el.classList.add("active");
  selectedPainLevel = level;
  selectedPainLabel = label;
  document.getElementById("painFeedback").textContent = "";
}

function logPain() {
  if (selectedPainLevel === null) {
    document.getElementById("painFeedback").textContent = "Please select a face first.";
    return;
  }
  document.getElementById("painDisplay").textContent = selectedPainLevel + " / 10";
  const status = document.getElementById("painStatus");
  const badge = document.getElementById("painBadge");
  const feedback = document.getElementById("painFeedback");
  badge.style.display = "inline-block";

  if (selectedPainLevel === 0) {
    status.textContent = "No pain — great!";
    feedback.textContent = "Wonderful! Keep up the great work!";
    feedback.style.color = "#15803d";
  } else if (selectedPainLevel <= 3) {
    status.textContent = "Mild — stable today";
    feedback.textContent = "Mild pain is normal. Keep following your plan.";
    feedback.style.color = "#15803d";
  } else if (selectedPainLevel <= 6) {
    status.textContent = "Moderate — take it easy";
    feedback.textContent = "Take it easy today and rest between exercises.";
    feedback.style.color = "#c2410c";
  } else if (selectedPainLevel <= 9) {
    status.textContent = "Severe — rest recommended";
    feedback.textContent = "Please rest and consider contacting Dr. Ahmed.";
    feedback.style.color = "#b91c1c";
  } else {
    status.textContent = "Worst — contact therapist";
    feedback.textContent = "Please contact your therapist immediately.";
    feedback.style.color = "#7f1d1d";
  }
}

const timers = {};
const currentSet = { heel: 1, leg: 1, quad: 1 };

function startExercise(id, seconds, totalSets) {
  if (timers[id]) { clearInterval(timers[id]); delete timers[id]; }

  const timerBox = document.getElementById("timer-" + id);
  const countEl = document.getElementById("count-" + id);
  const status = document.getElementById("status-" + id);
  const card = document.getElementById("card-" + id);
  const startBtn = document.getElementById("startbtn-" + id);
  const setsEl = document.getElementById("sets-" + id);

  let remaining = seconds;
  timerBox.style.display = "flex";
  countEl.textContent = remaining;
  status.textContent = "Set " + currentSet[id] + " in progress...";
  status.style.color = "#E8007D";
  card.style.borderColor = "#E8007D";
  startBtn.disabled = true;
  startBtn.textContent = "Running...";

  timers[id] = setInterval(() => {
    remaining--;
    countEl.textContent = remaining;
    if (remaining <= 0) {
      clearInterval(timers[id]);
      delete timers[id];
      timerBox.style.display = "none";
      if (currentSet[id] < totalSets) {
        currentSet[id]++;
        setsEl.textContent = "Set " + currentSet[id] + " of " + totalSets;
        status.textContent = "✓ Set done! Rest then start next set.";
        status.style.color = "#E8007D";
        startBtn.disabled = false;
        startBtn.textContent = "Start Set " + currentSet[id];
      } else {
        status.textContent = "All sets done! Click Mark Done.";
        status.style.color = "#15803d";
        startBtn.disabled = true;
        startBtn.textContent = "Done!";
      }
    }
  }, 1000);
}

function markDone(id) {
  if (timers[id]) { clearInterval(timers[id]); delete timers[id]; }
  const status = document.getElementById("status-" + id);
  const card = document.getElementById("card-" + id);
  const badge = document.getElementById("badge-" + id);
  const timerBox = document.getElementById("timer-" + id);
  const startBtn = document.getElementById("startbtn-" + id);
  if (timerBox) timerBox.style.display = "none";
  status.textContent = "Completed! ✓";
  status.style.color = "#15803d";
  card.style.borderColor = "#15803d";
  if (startBtn) { startBtn.disabled = true; startBtn.textContent = "Done!"; }
  if (badge) { badge.textContent = "Done"; badge.className = "badge green"; }
}

function sendMessage() {
  const input = document.getElementById("replyInput");
  const text = input.value.trim();
  if (!text) return;
  const chatBox = document.getElementById("chatBox");
  const now = new Date();
  const time = now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  const msg = document.createElement("div");
  msg.className = "message self";
  msg.innerHTML = `<strong>You</strong><p>${text}</p><span>${time}</span>`;
  chatBox.appendChild(msg);
  input.value = "";
  chatBox.scrollTop = chatBox.scrollHeight;
}

window.login = login;
window.logout = logout;
window.showSection = showSection;
window.selectFace = selectFace;
window.logPain = logPain;
window.startExercise = startExercise;
window.markDone = markDone;
window.sendMessage = sendMessage;