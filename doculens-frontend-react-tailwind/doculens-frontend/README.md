# DocuLens Frontend (React + Tailwind CSS)

A frontend built against the **actual routes** in the provided `doculens-person2-backend-with-schema.zip` FastAPI backend.

## Screens and features

- Login and signup using FastAPI JWT authentication
- Workspace dashboard and workspace creation
- PDF uploading (select a file; backend extracts and indexes it)
- Document text viewer grouped by PDF page, with matching `chunk-{id}` DOM IDs
- AI research chat and chat history
- Clickable citation chips: auto-switch document, scroll to referenced chunk, yellow highlight
- Pinned notes drawer: create / view / delete notes, and one-click pin an AI answer
- Dark/light theme, responsive desktop/mobile layout

**Important:** The backend currently returns **extracted text chunks**, not the original PDF bytes or PDF-coordinate rectangles. Therefore this frontend intentionally uses a **text-based page viewer** and highlights its source chunks. A pixel-accurate highlight over a rendered PDF requires new backend endpoints/coordinates.

## Setup on Windows (PowerShell)

1. Keep your existing DocuLens backend and MySQL database. Do not replace the backend or re-import your schema.
2. Start the **backend** in its own terminal:

   ```powershell
   cd path\to\doculens-backend
   .\.venv\Scripts\Activate.ps1
   python -m uvicorn main:app --reload
   ```

   Verify `http://127.0.0.1:8000/api/health`.

3. Extract this ZIP. Open `doculens-frontend` in VS Code. Run:

   ```powershell
   node --version
   npm install
   Copy-Item .env.example .env
   npm run dev
   ```

4. Visit **http://127.0.0.1:5173/**. Sign in with your existing DocuLens user (e.g. `student@example.com`, using *your* password).
5. Open an existing workspace, select an uploaded PDF, ask a question, click a citation, and pin the answer.

### If Node.js is not installed

Install a current **Node.js LTS** from https://nodejs.org/ and reopen VS Code. Verify `node --version` and `npm --version` before `npm install`.

### Environment

`.env` contains:

```env
VITE_API_BASE_URL=http://127.0.0.1:8000
```

This is **not** a MySQL URL. Never put MySQL passwords, Groq API keys, or JWT secrets into the frontend `.env`; those belong only in the FastAPI backend `.env`.

The backend's default CORS allowlist includes `http://localhost:5173`, but **not** `http://127.0.0.1:5173` in the supplied code. To avoid CORS errors, open the frontend with `http://localhost:5173` only if you have adjusted the Vite host, or preferably set the backend `.env` to:

```env
CORS_ORIGINS=http://127.0.0.1:5173,http://localhost:5173
```

Then **restart FastAPI**. This configuration is required when running the frontend on `127.0.0.1:5173`.

### Quick troubleshooting

- **Network error:** Start FastAPI and verify `/api/health`; check the backend CORS allowlist and restart FastAPI after updating `.env`.
- **401:** Sign in again; JWT tokens last 12 hours and are kept only for the current browser tab/session.
- **422 on uploads:** Use a PDF with selectable text (scanned-image PDFs require OCR, which the existing backend does not implement).
- **503 on upload:** Chroma may need to download its embedding model the first time.
- **502 on chat:** Check the backend `GROQ_API_KEY` and Groq model availability.
- **No matching citations:** The LLM might have returned an empty citation array; examine the backend API response in Swagger.

### API contract (confirmed against backend)

- `POST /api/auth/signup` body `{email,password}`
- `POST /api/auth/login` body `{email,password}` → `{access_token,token_type}`
- `GET /api/auth/me` → `{id,email}`
- `GET /api/workspaces`, `POST /api/workspaces` body `{name}`
- `GET/POST /api/workspaces/{workspace_id}/documents` (POST multipart field `file`)
- `GET /api/documents/{document_id}/chunks` → `[{id,dom_id,page,ordinal,text}]`
- `POST /api/workspaces/{workspace_id}/ask` body `{question,chat_id}` → `{chat_id,answer,citations}`
- `GET /api/workspaces/{workspace_id}/chats`, `GET /api/chats/{chat_id}/messages`
- `GET/POST /api/workspaces/{workspace_id}/notes`, `DELETE /api/notes/{note_id}`

## Notes

This frontend uses the existing backend and MySQL records. It does not need a separate schema. Authentication tokens are held in `sessionStorage`; do not treat that as a hardened production authentication design. Before deploying, consider HTTP-only cookies, strict CSP, rate limiting, and a proper file viewer API.
