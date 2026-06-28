import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.0/firebase-app.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  updateProfile,
  sendPasswordResetEmail,
  signOut
} from "https://www.gstatic.com/firebasejs/11.0.0/firebase-auth.js";

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

  const userName = auth.currentUser?.displayName || "Sarah";

  const el = document.getElementById("greeting");
  if (el) el.textContent = greet + ", " + userName;
}

/* Sign In / Sign Up / Forgot Password */

function showAuthForm(formName) {
  const loginForm = document.getElementById("loginForm");
  const signupForm = document.getElementById("signupForm");
  const resetForm = document.getElementById("resetForm");

  const loginTab = document.getElementById("loginTab");
  const signupTab = document.getElementById("signupTab");

  if (!loginForm || !signupForm || !resetForm || !loginTab || !signupTab) return;

  loginForm.classList.remove("active");
  signupForm.classList.remove("active");
  resetForm.classList.remove("active");

  loginTab.classList.remove("active");
  signupTab.classList.remove("active");

  if (formName === "login") {
    loginForm.classList.add("active");
    loginTab.classList.add("active");
  }

  if (formName === "signup") {
    signupForm.classList.add("active");
    signupTab.classList.add("active");
  }

  if (formName === "reset") {
    resetForm.classList.add("active");
  }
}

async function signup() {
  const name = document.getElementById("signupName").value.trim();
  const email = document.getElementById("signupEmail").value.trim();
  const password = document.getElementById("signupPassword").value;
  const confirmPassword = document.getElementById("confirmPassword").value;

  if (!name || !email || !password || !confirmPassword) {
    alert("Please fill in all fields.");
    return;
  }

  if (password.length < 6) {
    alert("Password must be at least 6 characters.");
    return;
  }

  if (password !== confirmPassword) {
    alert("Passwords do not match.");
    return;
  }

  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);

    await updateProfile(userCredential.user, {
      displayName: name
    });

    alert("Account created successfully!");

    document.getElementById("loginScreen").style.display = "none";
    document.getElementById("app").style.display = "block";

    setGreeting();
  } catch (error) {
    alert("Sign up failed: " + error.message);
  }
}

async function resetPassword() {
  const email = document.getElementById("resetEmail").value.trim();

  if (!email) {
    alert("Please enter your email.");
    return;
  }

  try {
    await sendPasswordResetEmail(auth, email);
    alert("Password reset link sent. Please check your email.");
    showAuthForm("login");
  } catch (error) {
    alert("Reset failed: " + error.message);
  }
}

async function login() {
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;

  if (!email || !password) {
    alert("Please enter your email and password.");
    return;
  }

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

  showAuthForm("login");
}

/* Navigation */

function showSection(sectionId, button) {
  document.querySelectorAll(".section").forEach(s => s.classList.remove("active"));
  document.querySelectorAll(".nav-btn").forEach(b => b.classList.remove("active"));

  document.getElementById(sectionId).classList.add("active");
  button.classList.add("active");
}

/* Pain Check-in */

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

/* Exercises */

const timers = {};
const currentSet = { heel: 1, leg: 1, quad: 1 };

function startExercise(id, seconds, totalSets) {
  if (timers[id]) {
    clearInterval(timers[id]);
    delete timers[id];
  }

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
  if (timers[id]) {
    clearInterval(timers[id]);
    delete timers[id];
  }

  const status = document.getElementById("status-" + id);
  const card = document.getElementById("card-" + id);
  const badge = document.getElementById("badge-" + id);
  const timerBox = document.getElementById("timer-" + id);
  const startBtn = document.getElementById("startbtn-" + id);

  if (timerBox) timerBox.style.display = "none";

  status.textContent = "Completed! ✓";
  status.style.color = "#15803d";
  card.style.borderColor = "#15803d";

  if (startBtn) {
    startBtn.disabled = true;
    startBtn.textContent = "Done!";
  }

  if (badge) {
    badge.textContent = "Done";
    badge.className = "badge green";
  }
}

/* Messages */

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

/* Application Profile / Maximum ROM / Speed Range */

const APPLICATION_PROFILE_KEY = "knevoApplicationProfile";

function getApplicationProfileElements() {
  return {
    patientId: document.getElementById("appPatientId"),
    profileType: document.getElementById("appProfileType"),
    recoveryStage: document.getElementById("appRecoveryStage"),

    minRom: document.getElementById("appMinRom"),
    maxRom: document.getElementById("appMaxRom"),

    assistLevel: document.getElementById("appAssistLevel"),
    motionSensitivity: document.getElementById("appMotionSensitivity"),
    motionSensitivityValue: document.getElementById("motionSensitivityValue"),

    minSpeed: document.getElementById("appMinSpeed"),
    maxSpeed: document.getElementById("appMaxSpeed"),
    currentSpeed: document.getElementById("appCurrentSpeed"),
    currentSpeedValue: document.getElementById("currentSpeedValue"),

    stagePreview: document.getElementById("stagePreview"),
    romRangePreview: document.getElementById("romRangePreview"),
    speedRangePreview: document.getElementById("speedRangePreview"),

    feedback: document.getElementById("appProfileFeedback")
  };
}

function updateApplicationProfilePreview() {
  const el = getApplicationProfileElements();

  if (!el.patientId) return;

  let minRom = el.minRom ? Number(el.minRom.value) : 0;
  let maxRom = el.maxRom ? Number(el.maxRom.value) : 120;

  if (Number.isNaN(minRom)) minRom = 0;
  if (Number.isNaN(maxRom)) maxRom = 120;

  if (minRom < 0) minRom = 0;
  if (maxRom > 130) maxRom = 130;

  if (minRom > maxRom) {
    maxRom = minRom;
  }

  if (el.minRom) el.minRom.value = minRom;
  if (el.maxRom) el.maxRom.value = maxRom;

  let minSpeed = Number(el.minSpeed.value);
  let maxSpeed = Number(el.maxSpeed.value);
  let currentSpeed = Number(el.currentSpeed.value);

  if (Number.isNaN(minSpeed)) minSpeed = 0;
  if (Number.isNaN(maxSpeed)) maxSpeed = 40;
  if (Number.isNaN(currentSpeed)) currentSpeed = minSpeed;

  if (minSpeed < 0) minSpeed = 0;

  if (maxSpeed < minSpeed) {
    maxSpeed = minSpeed;
  }

  if (currentSpeed < minSpeed) {
    currentSpeed = minSpeed;
  }

  if (currentSpeed > maxSpeed) {
    currentSpeed = maxSpeed;
  }

  el.minSpeed.value = minSpeed;
  el.maxSpeed.value = maxSpeed;
  el.currentSpeed.value = currentSpeed;

  el.currentSpeed.min = minSpeed;
  el.currentSpeed.max = maxSpeed;

  if (el.motionSensitivityValue && el.motionSensitivity) {
    el.motionSensitivityValue.textContent = el.motionSensitivity.value;
  }

  if (el.currentSpeedValue) {
    el.currentSpeedValue.textContent = currentSpeed;
  }

  if (el.stagePreview && el.recoveryStage) {
    el.stagePreview.textContent = el.recoveryStage.value;
  }

  if (el.romRangePreview) {
    el.romRangePreview.textContent = minRom + " - " + maxRom;
  }

  if (el.speedRangePreview) {
    el.speedRangePreview.textContent = minSpeed + " - " + maxSpeed;
  }
}

function saveApplicationProfile() {
  const el = getApplicationProfileElements();

  if (!el.patientId) return;

  updateApplicationProfilePreview();

  const applicationProfile = {
    patientId: el.patientId.value,
    profileType: el.profileType.value,
    recoveryStage: el.recoveryStage.value,

    minRom: el.minRom ? el.minRom.value : "0",
    maxRom: el.maxRom ? el.maxRom.value : "120",

    assistLevel: el.assistLevel ? el.assistLevel.value : "Low",
    motionSensitivity: el.motionSensitivity ? el.motionSensitivity.value : "5",

    minSpeed: el.minSpeed.value,
    maxSpeed: el.maxSpeed.value,
    currentSpeed: el.currentSpeed.value
  };

  localStorage.setItem(APPLICATION_PROFILE_KEY, JSON.stringify(applicationProfile));

  if (el.feedback) {
    el.feedback.textContent = "Application profile saved successfully.";

    setTimeout(() => {
      el.feedback.textContent = "";
    }, 2500);
  }
}

function loadApplicationProfile() {
  const el = getApplicationProfileElements();

  if (!el.patientId) return;

  const savedProfile = localStorage.getItem(APPLICATION_PROFILE_KEY);

  if (savedProfile) {
    const profile = JSON.parse(savedProfile);

    el.patientId.value = profile.patientId || "";
    el.profileType.value = profile.profileType || "Knee Rehabilitation";
    el.recoveryStage.value = profile.recoveryStage || "Phase 1 - Pain & Swelling Control";

    if (el.minRom) el.minRom.value = profile.minRom || 0;
    if (el.maxRom) el.maxRom.value = profile.maxRom || 120;

    if (el.assistLevel) el.assistLevel.value = profile.assistLevel || "Low";
    if (el.motionSensitivity) el.motionSensitivity.value = profile.motionSensitivity || 5;

    el.minSpeed.value = profile.minSpeed || 5;
    el.maxSpeed.value = profile.maxSpeed || 40;
    el.currentSpeed.value = profile.currentSpeed || 20;
  }

  updateApplicationProfilePreview();
}

function initApplicationProfile() {
  const el = getApplicationProfileElements();

  if (!el.patientId) return;

  [
    el.patientId,
    el.profileType,
    el.recoveryStage,
    el.minRom,
    el.maxRom,
    el.assistLevel,
    el.motionSensitivity,
    el.minSpeed,
    el.maxSpeed,
    el.currentSpeed
  ]
    .filter(input => input !== null)
    .forEach(input => {
      input.addEventListener("input", updateApplicationProfilePreview);
      input.addEventListener("change", updateApplicationProfilePreview);
    });

  loadApplicationProfile();
}

/* Make functions clickable from HTML */
window.login = login;
window.logout = logout;
window.showSection = showSection;
window.selectFace = selectFace;
window.logPain = logPain;
window.startExercise = startExercise;
window.markDone = markDone;
window.sendMessage = sendMessage;
window.saveApplicationProfile = saveApplicationProfile;

window.showAuthForm = showAuthForm;
window.signup = signup;
window.resetPassword = resetPassword;

/* Start profile code after clickable functions are available */
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initApplicationProfile);
} else {
  initApplicationProfile();
}