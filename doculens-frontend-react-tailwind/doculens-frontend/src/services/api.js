const API_BASE = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000').replace(/\/+$/, '')

export class ApiError extends Error {
  constructor(message, status) { super(message); this.name = 'ApiError'; this.status = status }
}

async function request(path, { method = 'GET', token, body, upload = false } = {}) {
  const headers = { ...(token ? { Authorization: `Bearer ${token}` } : {}) }
  if (body && !upload) headers['Content-Type'] = 'application/json'
  let response
  try {
    response = await fetch(`${API_BASE}${path}`, { method, headers, body: upload ? body : body === undefined ? undefined : JSON.stringify(body) })
  } catch {
    throw new ApiError('Cannot reach the DocuLens backend. Start FastAPI on port 8000 and check CORS.', 0)
  }
  if (!response.ok) {
    let detail = `Request failed (HTTP ${response.status})`
    try {
      const data = await response.json()
      detail = typeof data.detail === 'string' ? data.detail : Array.isArray(data.detail) ? data.detail.map(x => x.msg).join(', ') : detail
    } catch { /* non-JSON response */ }
    throw new ApiError(detail, response.status)
  }
  if (response.status === 204) return null
  return response.json()
}

export const api = {
  signup: (email, password) => request('/api/auth/signup', { method: 'POST', body: { email, password } }),
  login: (email, password) => request('/api/auth/login', { method: 'POST', body: { email, password } }),
  me: token => request('/api/auth/me', { token }),
  workspaces: token => request('/api/workspaces', { token }),
  createWorkspace: (token, name) => request('/api/workspaces', { method: 'POST', token, body: { name } }),
  documents: (token, workspaceId) => request(`/api/workspaces/${workspaceId}/documents`, { token }),
  uploadDocument: (token, workspaceId, file) => { const fd = new FormData(); fd.append('file', file); return request(`/api/workspaces/${workspaceId}/documents`, { method:'POST', token, body: fd, upload: true }) },
  chunks: (token, documentId) => request(`/api/documents/${documentId}/chunks`, { token }),
  ask: (token, workspaceId, question, chatId = null) => request(`/api/workspaces/${workspaceId}/ask`, { method:'POST', token, body: { question, chat_id: chatId } }),
  chats: (token, workspaceId) => request(`/api/workspaces/${workspaceId}/chats`, { token }),
  messages: (token, chatId) => request(`/api/chats/${chatId}/messages`, { token }),
  notes: (token, workspaceId) => request(`/api/workspaces/${workspaceId}/notes`, { token }),
  pin: (token, workspaceId, text, sourceMessageId = null) => request(`/api/workspaces/${workspaceId}/notes`, { method:'POST', token, body: { text, source_message_id: sourceMessageId } }),
  deleteNote: (token, noteId) => request(`/api/notes/${noteId}`, { method:'DELETE', token }),
}
