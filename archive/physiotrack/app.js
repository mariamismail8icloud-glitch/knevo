function login() {
  document.getElementById("loginScreen").style.display = "none";
  document.getElementById("app").style.display = "block";
}

function logout() {
  document.getElementById("app").style.display = "none";
  document.getElementById("loginScreen").style.display = "flex";
}

function showSection(sectionId, button) {
  const sections = document.querySelectorAll(".section");
  sections.forEach(section => section.classList.remove("active"));

  const navButtons = document.querySelectorAll(".nav-link");
  navButtons.forEach(btn => btn.classList.remove("active"));

  document.getElementById(sectionId).classList.add("active");
  button.classList.add("active");
}