import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getExercises, type Exercise } from '../../api/doctorApi';

const CATEGORIES = [
  'All', 'Standing exercises', 'Walking / gait exercises', 'Knee control exercises',
  'Balance exercises', 'Strength exercises', 'Range of motion exercises',
  'Functional exercises', 'Warm-up exercises', 'Cool-down exercises', 'Assessment exercises',
];

const MODE_COLOR: Record<string, string> = {
  DEVICE_ASSISTED: 'bg-[#fce8f3] text-[#E8007D]',
  MOBILE_ONLY: 'bg-blue-50 text-blue-600',
};

const DIFFICULTY_COLOR: Record<string, string> = {
  BEGINNER: 'bg-green-50 text-green-700',
  INTERMEDIATE: 'bg-yellow-50 text-yellow-700',
  ADVANCED: 'bg-red-50 text-red-700',
};

export default function ExerciseLibraryPage() {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('All');
  const [selected, setSelected] = useState<Exercise | null>(null);

  const { data: exercises = [], isLoading } = useQuery({
    queryKey: ['exercises', category],
    queryFn: () => getExercises(category !== 'All' ? { category } : undefined),
  });

  const filtered = exercises.filter(e =>
    e.name.toLowerCase().includes(search.toLowerCase()) ||
    e.description?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center gap-3 mb-6">
          <a href="/dashboard" className="text-[#64748b] hover:text-[#E8007D] text-sm">← Dashboard</a>
        </div>
        <h1 className="text-2xl font-bold text-[#0f172a] mb-6">Exercise Library</h1>

        <div className="flex flex-col sm:flex-row gap-4 mb-6">
          <input
            type="text"
            placeholder="Search exercises…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="flex-1 px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-white focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]"
          />
        </div>

        <div className="flex flex-wrap gap-2 mb-6">
          {CATEGORIES.map(cat => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${
                category === cat
                  ? 'bg-[#E8007D] text-white'
                  : 'bg-white border border-[#f0d6e8] text-[#64748b] hover:border-[#E8007D] hover:text-[#E8007D]'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>

        {isLoading ? (
          <div className="text-center py-12 text-[#64748b]">Loading exercises…</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filtered.map(ex => (
              <div
                key={ex.id}
                onClick={() => setSelected(ex)}
                className="bg-white rounded-2xl border border-[#f0d6e8] p-5 cursor-pointer hover:border-[#E8007D] hover:shadow-knevo transition-all"
              >
                <div className="flex items-start justify-between mb-3">
                  <h3 className="font-semibold text-[#0f172a] flex-1">{ex.name}</h3>
                </div>
                <p className="text-sm text-[#64748b] mb-3 line-clamp-2">{ex.description}</p>
                <div className="flex flex-wrap gap-2">
                  <span className={`px-2 py-1 rounded-lg text-xs font-medium ${MODE_COLOR[ex.mode] ?? 'bg-gray-100 text-gray-600'}`}>
                    {ex.mode === 'DEVICE_ASSISTED' ? 'Device' : 'Mobile only'}
                  </span>
                  <span className={`px-2 py-1 rounded-lg text-xs font-medium ${DIFFICULTY_COLOR[ex.difficulty] ?? 'bg-gray-100 text-gray-600'}`}>
                    {ex.difficulty}
                  </span>
                  <span className="px-2 py-1 rounded-lg text-xs font-medium bg-[#fdf5f9] text-[#64748b]">{ex.targetJoint}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {filtered.length === 0 && !isLoading && (
          <div className="text-center py-12 text-[#64748b]">No exercises found.</div>
        )}
      </div>

      {/* Exercise detail modal */}
      {selected && (
        <div className="fixed inset-0 bg-black/30 flex items-center justify-center p-6 z-50" onClick={() => setSelected(null)}>
          <div className="w-full max-w-lg bg-white rounded-3xl p-8 shadow-2xl max-h-[80vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
            <div className="flex items-start justify-between mb-4">
              <h2 className="text-xl font-bold text-[#0f172a]">{selected.name}</h2>
              <button onClick={() => setSelected(null)} className="text-[#64748b] hover:text-[#0f172a] ml-4">✕</button>
            </div>
            <div className="flex gap-2 mb-4">
              <span className={`px-2 py-1 rounded-lg text-xs font-medium ${MODE_COLOR[selected.mode] ?? ''}`}>{selected.mode}</span>
              <span className={`px-2 py-1 rounded-lg text-xs font-medium ${DIFFICULTY_COLOR[selected.difficulty] ?? ''}`}>{selected.difficulty}</span>
            </div>
            <div className="space-y-4 text-sm">
              <div><p className="font-semibold text-[#334155] mb-1">Description</p><p className="text-[#64748b]">{selected.description}</p></div>
              {selected.patientInstructions && <div><p className="font-semibold text-[#334155] mb-1">Patient instructions</p><p className="text-[#64748b]">{selected.patientInstructions}</p></div>}
              {selected.doctorInstructions && <div><p className="font-semibold text-[#334155] mb-1">Clinical notes</p><p className="text-[#64748b]">{selected.doctorInstructions}</p></div>}
              {selected.safetyNotes && <div><p className="font-semibold text-[#334155] mb-1">Safety notes</p><p className="text-[#64748b]">{selected.safetyNotes}</p></div>}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
