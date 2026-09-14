// js/app.js
import { Patients, Messages, ExerciseLibrary, statusClass, statusLabel } from "./data.js";

function $(sel){ return document.querySelector(sel); }
function $all(sel){ return Array.from(document.querySelectorAll(sel)); }

function setActiveNav(){
  const path = location.pathname.split("/").pop() || "index.html";
  $all('[data-nav]').forEach(a => {
    a.classList.toggle("active", a.getAttribute("href") === path);
  });
}

function applyThemeFromStorage(){
  const t = localStorage.getItem("pt_theme") || "light";
  document.documentElement.setAttribute("data-theme", t);
  const label = $("#themeLabel");
  if (label) label.textContent = (t === "dark") ? "Dark" : "Light";
}

function toggleTheme(){
  const curr = document.documentElement.getAttribute("data-theme") || "light";
  const next = (curr === "dark") ? "light" : "dark";
  document.documentElement.setAttribute("data-theme", next);
  localStorage.setItem("pt_theme", next);
  const label = $("#themeLabel");
  if (label) label.textContent = (next === "dark") ? "Dark" : "Light";
}

function deviceHint(){
  const w = window.innerWidth;
  if (w <= 820) return "Mobile";
  if (w <= 1100) return "Tablet";
  return "Laptop";
}

function updateDeviceHint(){
  const el = $("#deviceHint");
  if (el) el.textContent = deviceHint();
}

function counts(){
  const improving = Patients.filter(p=>p.status==="improving").length;
  const stable = Patients.filter(p=>p.status==="stable").length;
  const attention = Patients.filter(p=>p.status==="needs-attention").length;
  return { improving, stable, attention, total: Patients.length };
}

function mountDashboard(){
  const c = counts();
  const a = $("#countImproving"); if (a) a.textContent = c.improving;
  const b = $("#countStable"); if (b) b.textContent = c.stable;
  const d = $("#countAttention"); if (d) d.textContent = c.attention;

  // render patient cards (home)
  const grid = $("#patientsGrid");
  if (grid){
    grid.innerHTML = Patients.map(p => patientCardHTML(p)).join("");
    attachCardClicks(grid);
  }

  // alerts table (home)
  const alertTable = $("#alertsTableBody");
  if (alertTable){
    const alertPatients = Patients
      .filter(p => p.status === "needs-attention" || p.alerts.some(x=>x!=="None"))
      .slice(0,5);

    alertTable.innerHTML = alertPatients.map(p => `
      <tr>
        <td><b>${p.name}</b><div style="color:var(--muted);font-size:12px">${p.id}</div></td>
        <td>${p.device === "online" ? "🟢 Online" : "🔴 Offline"}</td>
        <td>${p.alerts.filter(x=>x!=="None").slice(0,2).join(", ") || "—"}</td>
        <td><a href="patient-details.html?id=${encodeURIComponent(p.id)}">Open</a></td>
      </tr>
    `).join("") || `<tr><td colspan="4">No alerts 🎉</td></tr>`;
  }
}

function patientCardHTML(p){
  const badge = statusClass(p.status);
  return `
  <div class="patient-card" data-open="${p.id}">
    <div class="patient-top">
      <div class="avatar">👤</div>
      <div style="min-width:0">
        <div style="font-weight:800">${p.name}</div>
        <div class="patient-id">ID: ${p.id}</div>
      </div>
      <span class="badge ${badge}">${statusLabel(p.status)}</span>
    </div>

    <ul class="kv">
      <li>📅 <span>Next visit:</span> ${p.nextVisit}</li>
      <li>🧾 <span>Exercises:</span> ${p.exercisesDone}/${p.exercisesTotal}</li>
      <li>📈 <span>Progress:</span> ${p.progress}%</li>
    </ul>
    <div class="divider"></div>
    <div class="diagnosis">${p.diagnosis}</div>
  </div>
  `;
}

function attachCardClicks(container){
  container.addEventListener("click", (e)=>{
    const card = e.target.closest(".patient-card");
    if (!card) return;
    const id = card.getAttribute("data-open");
    location.href = `patient-details.html?id=${encodeURIComponent(id)}`;
  });
}

function mountPatientsPage(){
  const grid = $("#patientsGrid");
  if (!grid) return;

  let filter = "all";
  const input = $("#searchInput");
  const chips = $all("[data-filter]");

  function render(){
    const q = (input?.value || "").trim().toLowerCase();
    const list = Patients.filter(p=>{
      const matchQ =
        p.name.toLowerCase().includes(q) ||
        p.id.toLowerCase().includes(q) ||
        p.diagnosis.toLowerCase().includes(q);

      const matchFilter =
        filter === "all" ? true :
        filter === "improving" ? p.status==="improving" :
        filter === "stable" ? p.status==="stable" :
        p.status==="needs-attention";

      return matchQ && matchFilter;
    });

    $("#patientsCount").textContent = `${list.length}`;
    grid.innerHTML = list.map(patientCardHTML).join("") || `<div class="card">No patients found.</div>`;
  }

  chips.forEach(ch => ch.addEventListener("click", ()=>{
    chips.forEach(x=>x.classList.remove("active"));
    ch.classList.add("active");
    filter = ch.getAttribute("data-filter");
    render();
  }));

  input?.addEventListener("input", render);

  render();
  attachCardClicks(grid);
}

function mountPatientDetails(){
  const root = $("#patientDetailsRoot");
  if (!root) return;

  const params = new URLSearchParams(location.search);
  const id = params.get("id") || "PT-001";
  const p = Patients.find(x=>x.id===id) || Patients[0];

  $("#pdName").textContent = p.name;
  $("#pdId").textContent = p.id;
  $("#pdDiagnosis").textContent = p.diagnosis;
  $("#pdNext").textContent = p.nextVisit;
  $("#pdPain").textContent = `${p.painAvg}/10`;
  $("#pdCompliance").textContent = `${p.compliance}%`;
  $("#pdDevice").textContent = (p.device==="online") ? "🟢 Online" : "🔴 Offline";
  $("#pdNotes").textContent = p.notes;

  // Build alerts list
  const al = $("#pdAlerts");
  const alerts = p.alerts.filter(x=>x!=="None");
  al.innerHTML = alerts.length ? alerts.map(x=>`<li>${x}</li>`).join("") : `<li>No alerts</li>`;

  // Quick actions (mock)
  $("#btnCall")?.addEventListener("click", ()=> alert(`Calling ${p.name} (mock)…`));
  $("#btnMessage")?.addEventListener("click", ()=> location.href = `messages.html?patient=${encodeURIComponent(p.id)}`);
  $("#btnAdjust")?.addEventListener("click", ()=> location.href = `exercises.html?patient=${encodeURIComponent(p.id)}`);

  // Charts (Chart.js CDN must be included on page)
  if (window.Chart){
    mountCharts(p);
  }
}

function mountCharts(p){
  // Sample series based on progress/pain/compliance
  const labels = ["W1","W2","W3","W4","W5","W6"];
  const base = p.progress;

  const progressSeries = [Math.max(0, base-25), Math.max(0, base-18), Math.max(0, base-12), Math.max(0, base-7), Math.max(0, base-3), base];
  const painSeries = [Math.min(10, p.painAvg+2), Math.min(10, p.painAvg+1), p.painAvg, Math.max(0, p.painAvg-1), Math.max(0, p.painAvg-1), p.painAvg];
  const complianceSeries = [Math.max(0, p.compliance-20), Math.max(0, p.compliance-14), Math.max(0, p.compliance-10), Math.max(0, p.compliance-6), Math.max(0, p.compliance-3), p.compliance];

  const ctx1 = $("#chartProgress");
  const ctx2 = $("#chartPain");
  const ctx3 = $("#chartCompliance");

  new Chart(ctx1, {
    type:"line",
    data:{ labels, datasets:[{ label:"Rehab Progress (%)", data:progressSeries, tension:.35 }] },
    options:{ responsive:true, plugins:{ legend:{ display:false } }, scales:{ y:{ beginAtZero:true, max:100 } } }
  });

  new Chart(ctx2, {
    type:"line",
    data:{ labels, datasets:[{ label:"Pain (0–10)", data:painSeries, tension:.35 }] },
    options:{ responsive:true, plugins:{ legend:{ display:false } }, scales:{ y:{ beginAtZero:true, max:10 } } }
  });

  new Chart(ctx3, {
    type:"bar",
    data:{ labels, datasets:[{ label:"Compliance (%)", data:complianceSeries }] },
    options:{ responsive:true, plugins:{ legend:{ display:false } }, scales:{ y:{ beginAtZero:true, max:100 } } }
  });
}

function mountExercises(){
  const lib = $("#exerciseLibrary");
  if (!lib) return;

  const params = new URLSearchParams(location.search);
  const patient = params.get("patient");
  if (patient){
    const p = Patients.find(x=>x.id===patient);
    if (p){
      $("#exForPatient").textContent = `Plan for: ${p.name} (${p.id})`;
    }
  }

  lib.innerHTML = ExerciseLibrary.map((ex, idx)=>`
    <tr>
      <td><b>${ex.name}</b><div style="color:var(--muted);font-size:12px">${ex.category}</div></td>
      <td>${ex.sets}</td>
      <td>${ex.reps}</td>
      <td style="color:var(--muted)">${ex.notes}</td>
      <td><button class="btn" data-add="${idx}">Add</button></td>
    </tr>
  `).join("");

  const plan = $("#currentPlan");
  let planItems = [];

  lib.addEventListener("click",(e)=>{
    const btn = e.target.closest("[data-add]");
    if (!btn) return;
    const ex = ExerciseLibrary[Number(btn.getAttribute("data-add"))];
    planItems.push(ex);
    renderPlan();
  });

  $("#btnClearPlan")?.addEventListener("click", ()=>{
    planItems = [];
    renderPlan();
  });

  $("#btnSavePlan")?.addEventListener("click", ()=>{
    alert("Saved plan (mock). You can connect this to Firebase later.");
  });

  function renderPlan(){
    plan.innerHTML = planItems.length ? planItems.map((x,i)=>`
      <div class="card" style="padding:12px;display:flex;justify-content:space-between;align-items:center;gap:10px">
        <div style="min-width:0">
          <b>${x.name}</b>
          <div style="color:var(--muted);font-size:12px">${x.category} • ${x.sets} sets • ${x.reps} reps</div>
        </div>
        <button class="btn" data-remove="${i}">Remove</button>
      </div>
    `).join("") : `<div class="card">No exercises added yet.</div>`;

    plan.querySelectorAll("[data-remove]").forEach(btn=>{
      btn.addEventListener("click", ()=>{
        const i = Number(btn.getAttribute("data-remove"));
        planItems.splice(i,1);
        renderPlan();
      });
    });
  }

  renderPlan();
}

function mountMessages(){
  const list = $("#inboxList");
  const threadEl = $("#thread");
  if (!list || !threadEl) return;

  let active = null;

  function renderInbox(){
    list.innerHTML = Messages.map(m=>`
      <div class="card" data-open="${m.patientId}" style="padding:12px;cursor:pointer;border-radius:14px">
        <div style="display:flex;justify-content:space-between;gap:10px">
          <div style="min-width:0">
            <b>${m.patientName}</b>
            <div style="color:var(--muted);font-size:12px">(${m.patientId})</div>
          </div>
          ${m.unread ? `<span class="badge warn" style="position:static">${m.unread} new</span>` : ``}
        </div>
        <div style="color:var(--muted);font-size:13px;margin-top:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">
          ${m.last}
        </div>
      </div>
    `).join("");
  }

  function renderThread(msg){
    threadEl.innerHTML = msg.thread.map(t=>`
      <div>
        <div class="bubble ${t.from==="doctor" ? "me" : ""}">
          ${escapeHTML(t.text)}
        </div>
        <div class="meta ${t.from==="doctor" ? "me" : ""}">
          ${t.from === "doctor" ? "You" : msg.patientName} • ${t.time}
        </div>
      </div>
    `).join("");
    threadEl.scrollTop = threadEl.scrollHeight;
    $("#chatTitle").textContent = `${msg.patientName} (${msg.patientId})`;
  }

  function openById(id){
    active = Messages.find(x=>x.patientId===id) || Messages[0];
    renderThread(active);
    $all("#inboxList .card").forEach(c=>{
      c.style.outline = (c.getAttribute("data-open")===active.patientId) ? `2px solid rgba(37,99,235,.25)` : "none";
    });
  }

  list.addEventListener("click",(e)=>{
    const item = e.target.closest("[data-open]");
    if (!item) return;
    openById(item.getAttribute("data-open"));
  });

  $("#btnSend")?.addEventListener("click", ()=>{
    if (!active) return;
    const input = $("#chatText");
    const text = (input.value||"").trim();
    if (!text) return;
    active.thread.push({ from:"doctor", text, time: new Date().toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'}) });
    active.last = text;
    input.value = "";
    renderInbox();
    openById(active.patientId);
  });

  // Open from query param
  const params = new URLSearchParams(location.search);
  const pid = params.get("patient");

  renderInbox();
  openById(pid || Messages[0].patientId);
}

function mountReports(){
  const btn = $("#btnPrint");
  if (!btn) return;
  btn.addEventListener("click", ()=>{
    window.print(); // user can "Save as PDF"
  });

  const summary = $("#reportSummary");
  if (summary){
    const c = counts();
    const offline = Patients.filter(p=>p.device==="offline").length;
    const avgCompliance = Math.round(Patients.reduce((s,p)=>s+p.compliance,0)/Patients.length);
    summary.innerHTML = `
      <div class="grid-3">
        <div class="card"><h3>Total Patients</h3><p class="big">${c.total}</p></div>
        <div class="card"><h3>Devices Offline</h3><p class="big">${offline}</p></div>
        <div class="card"><h3>Avg Compliance</h3><p class="big">${avgCompliance}%</p></div>
      </div>
    `;
  }

  const table = $("#reportTableBody");
  if (table){
    table.innerHTML = Patients.map(p=>`
      <tr>
        <td><b>${p.name}</b><div style="color:var(--muted);font-size:12px">${p.id}</div></td>
        <td>${statusLabel(p.status)}</td>
        <td>${p.progress}%</td>
        <td>${p.painAvg}/10</td>
        <td>${p.compliance}%</td>
        <td>${p.device==="online" ? "🟢" : "🔴"}</td>
      </tr>
    `).join("");
  }
}

function escapeHTML(s){
  return s.replace(/[&<>"']/g, m => ({
    "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"
  }[m]));
}

// Init
document.addEventListener("DOMContentLoaded", ()=>{
  applyThemeFromStorage();
  setActiveNav();
  updateDeviceHint();
  window.addEventListener("resize", updateDeviceHint);

  $("#btnTheme")?.addEventListener("click", toggleTheme);

  mountDashboard();
  mountPatientsPage();
  mountPatientDetails();
  mountExercises();
  mountMessages();
  mountReports();
});
