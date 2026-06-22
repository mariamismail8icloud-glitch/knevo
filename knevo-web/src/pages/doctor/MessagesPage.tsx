import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { getMyPatients, getMessageThread, sendMessage } from '../../api/doctorApi';

export default function MessagesPage() {
  const [selectedPatientId, setSelectedPatientId] = useState<string | null>(null);
  const [input, setInput] = useState('');
  const doctorId = sessionStorage.getItem('userId') ?? '';

  const { data: patients = [] } = useQuery({
    queryKey: ['my-patients'],
    queryFn: getMyPatients,
  });

  const { data: messages = [], refetch } = useQuery({
    queryKey: ['thread', selectedPatientId, doctorId],
    queryFn: () => getMessageThread(selectedPatientId!),
    enabled: !!selectedPatientId,
    refetchInterval: 5000,
  });

  const sendMutation = useMutation({
    mutationFn: () => sendMessage({ body: input, receiverId: selectedPatientId! }),
    onSuccess: () => {
      setInput('');
      refetch();
    },
  });

  return (
    <div className="min-h-screen bg-[#fdf5f9] flex">
      {/* Left: patient list */}
      <div className="w-64 bg-white border-r border-[#f0d6e8] flex flex-col">
        <div className="p-5 border-b border-[#f0d6e8]">
          <div className="flex items-center gap-3 mb-4">
            <a href="/dashboard" className="text-[#64748b] hover:text-[#E8007D] text-sm">
              ← Dashboard
            </a>
          </div>
          <h2 className="font-bold text-[#0f172a]">Messages</h2>
        </div>
        <div className="flex-1 overflow-y-auto">
          {patients.map(p => (
            <button
              key={p.id}
              onClick={() => setSelectedPatientId(p.id)}
              className={`w-full text-left px-5 py-4 hover:bg-[#fdf5f9] transition-colors border-b border-[#f0d6e8] ${
                selectedPatientId === p.id
                  ? 'bg-[#fdf5f9] border-l-2 border-l-[#E8007D]'
                  : ''
              }`}
            >
              <p className="font-medium text-[#0f172a] text-sm">{p.name}</p>
              {p.email && (
                <p className="text-xs text-[#64748b] truncate">{p.email}</p>
              )}
            </button>
          ))}
          {patients.length === 0 && (
            <p className="p-5 text-[#64748b] text-sm">No patients yet.</p>
          )}
        </div>
      </div>

      {/* Right: chat */}
      <div className="flex-1 flex flex-col">
        {selectedPatientId ? (
          <>
            <div className="p-5 bg-white border-b border-[#f0d6e8]">
              <h3 className="font-semibold text-[#0f172a]">
                {patients.find(p => p.id === selectedPatientId)?.name ?? 'Patient'}
              </h3>
            </div>
            <div className="flex-1 overflow-y-auto p-6 space-y-3">
              {messages.map(msg => (
                <div
                  key={msg.id}
                  className={`flex ${msg.senderId === doctorId ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-xs px-4 py-2.5 rounded-2xl text-sm ${
                      msg.senderId === doctorId
                        ? 'bg-[#E8007D] text-white rounded-br-sm'
                        : 'bg-white border border-[#f0d6e8] text-[#0f172a] rounded-bl-sm'
                    }`}
                  >
                    <p>{msg.body}</p>
                    <p
                      className={`text-xs mt-1 ${
                        msg.senderId === doctorId ? 'text-white/70' : 'text-[#64748b]'
                      }`}
                    >
                      {new Date(msg.sentAt).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </p>
                  </div>
                </div>
              ))}
              {messages.length === 0 && (
                <p className="text-center text-[#64748b] text-sm py-8">
                  No messages yet. Say hello!
                </p>
              )}
            </div>
            <div className="p-4 bg-white border-t border-[#f0d6e8] flex gap-3">
              <input
                value={input}
                onChange={e => setInput(e.target.value)}
                onKeyDown={e => {
                  if (e.key === 'Enter' && input.trim()) sendMutation.mutate();
                }}
                placeholder="Type a message…"
                className="flex-1 px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]"
              />
              <button
                onClick={() => sendMutation.mutate()}
                disabled={!input.trim() || sendMutation.isPending}
                className="px-5 py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] disabled:opacity-50"
              >
                Send
              </button>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center">
            <p className="text-[#64748b]">Select a patient to view messages.</p>
          </div>
        )}
      </div>
    </div>
  );
}
