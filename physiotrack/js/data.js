// js/data.js
export const Patients = [
  {
    id: "PT-001",
    name: "Sarah Johnson",
    status: "improving",
    nextVisit: "Dec 30, 2025",
    exercisesDone: 8,
    exercisesTotal: 10,
    progress: 75,
    diagnosis: "ACL Reconstruction Recovery",
    painAvg: 3,
    compliance: 82,
    device: "online",
    alerts: ["None"],
    notes: "Focus on quad activation + ROM."
  },
  {
    id: "PT-002",
    name: "Michael Chen",
    status: "stable",
    nextVisit: "Jan 2, 2026",
    exercisesDone: 5,
    exercisesTotal: 8,
    progress: 60,
    diagnosis: "Meniscus Tear – Conservative Treatment",
    painAvg: 2,
    compliance: 74,
    device: "online",
    alerts: ["Occasional swelling after long walk"],
    notes: "Gradual load increase, monitor swelling."
  },
  {
    id: "PT-003",
    name: "Emily Rodriguez",
    status: "improving",
    nextVisit: "Jan 5, 2026",
    exercisesDone: 6,
    exercisesTotal: 9,
    progress: 80,
    diagnosis: "Patellofemoral Pain Syndrome",
    painAvg: 4,
    compliance: 88,
    device: "online",
    alerts: ["Pain spikes on stairs"],
    notes: "Hip strengthening, reduce stair volume."
  },
  {
    id: "PT-004",
    name: "David Thompson",
    status: "needs-attention",
    nextVisit: "Dec 28, 2025",
    exercisesDone: 3,
    exercisesTotal: 8,
    progress: 45,
    diagnosis: "Total Knee Replacement Recovery",
    painAvg: 6,
    compliance: 52,
    device: "offline",
    alerts: ["Low compliance", "Device disconnected", "Pain increased"],
    notes: "Call patient, reassess plan, check device pairing."
  }
];

export const Messages = [
  {
    patientId: "PT-003",
    patientName: "Emily Rodriguez",
    unread: 2,
    last: "My knee hurts more when I climb stairs.",
    thread: [
      { from: "patient", text: "Hi doc, my knee hurts more when I climb stairs.", time: "09:14" },
      { from: "doctor", text: "Thanks Emily. Reduce stairs today and do hip exercises.", time: "09:20" },
      { from: "patient", text: "Okay, should I ice it?", time: "09:22" },
      { from: "patient", text: "Also I felt a small click.", time: "09:23" }
    ]
  },
  {
    patientId: "PT-001",
    patientName: "Sarah Johnson",
    unread: 0,
    last: "Completed today’s exercises ✅",
    thread: [
      { from: "patient", text: "Completed today’s exercises ✅", time: "18:05" },
      { from: "doctor", text: "Great. Keep your ROM gentle and consistent.", time: "18:10" }
    ]
  },
  {
    patientId: "PT-004",
    patientName: "David Thompson",
    unread: 1,
    last: "My device is not connecting.",
    thread: [
      { from: "patient", text: "My device is not connecting.", time: "12:41" }
    ]
  }
];

export const ExerciseLibrary = [
  { name: "Knee Flexion (Seated)", category: "ROM", sets: "3", reps: "10", notes: "Slow controlled movement." },
  { name: "Straight Leg Raise", category: "Strength", sets: "3", reps: "12", notes: "Keep knee locked." },
  { name: "Quad Sets", category: "Activation", sets: "3", reps: "15", notes: "Hold 5 seconds." },
  { name: "Balance (Single Leg)", category: "Balance", sets: "3", reps: "30s", notes: "Near a support surface." }
];

export function statusLabel(s){
  if (s === "improving") return "improving";
  if (s === "stable") return "stable";
  return "needs attention";
}

export function statusClass(s){
  if (s === "improving") return "good";
  if (s === "stable") return "stable";
  return "warn";
}
