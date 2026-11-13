# DocuLens — Person 2 Backend (Windows + MySQL Workbench)

This is the **backend**, not a React frontend. It includes `main.py`, a real MySQL Workbench schema file, and FastAPI endpoints for login, workspaces, PDF upload, PDF chunks, RAG citation chat, and notes.

## 1. Import the MySQL schema FIRST (same approach as NovaStore)

1. Open **MySQL Workbench**, connect to your **local root MySQL connection**.
2. Click **File → Open SQL Script**.
3. Select **`database/schema.sql`** in the extracted project.
4. Click the **lightning bolt** to execute all statements.
5. Under SCHEMAS on the left click **Refresh**, expand `doculens` → **Tables**.
6. You should see: `users`, `workspaces`, `documents`, `chunks`, `chats`, `messages`, `notes`.

You do **not** need to create `doculens_user` or run GRANT statements. The script uses CREATE DATABASE/TABLE IF NOT EXISTS, so you may safely rerun it without erasing data. These seven tables start empty and fill when you use the app. Chroma stores embeddings separately in `chroma_data/`, not in MySQL.

## 2. Install Python packages (PowerShell terminal in VS Code)

Open the **extracted `doculens-backend`** folder as your VS Code workspace. Run:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

If Python 3.11 isn't installed, install it first. If Windows blocks venv activation, use `.\.venv\Scripts\python.exe -m pip install -r requirements.txt` and `.\.venv\Scripts\python.exe -m uvicorn main:app --reload` instead.

## 3. Configure `.env`

Edit `.env` (not `.env.example`):

```env
DATABASE_URL=mysql+pymysql://root:YOUR_ROOT_PASSWORD@127.0.0.1:3306/doculens
JWT_SECRET=YOUR_GENERATED_RANDOM_SECRET_AT_LEAST_32_CHARACTERS
GROQ_API_KEY=YOUR_KEY_FROM_GROQ
GROQ_MODEL=openai/gpt-oss-20b
CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173
UPLOAD_DIR=./uploads
CHROMA_DIR=./chroma_data
MAX_PDF_MB=15
```

Use your **own** local MySQL root password. Do not share it or commit `.env` to GitHub. If the password contains `@`, `#`, `:`, `/`, or `%`, URL-encode it in `DATABASE_URL` (for example `@` → `%40`). To create a JWT secret:

```powershell
python -c "import secrets; print(secrets.token_urlsafe(48))"
```

Groq API key comes from https://console.groq.com/keys. You can test `/api/health`, signup and login before setting a Groq key; AI answering requires the key. The first document upload can download Chroma's local embedding model and requires an internet connection.

## 4. Run and test

```powershell
python -m uvicorn main:app --reload
```

Open http://127.0.0.1:8000/docs and test in this order:

1. `GET /api/health` → `{"status":"ok","project":"DocuLens"}`
2. `POST /api/auth/signup` → JSON `{"email":"test@example.com","password":"SecurePass123!"}`
3. `POST /api/auth/login` → same body; copy `access_token`
4. Click Swagger **Authorize**, paste the access token (Swagger handles Bearer), confirm.
5. `POST /api/workspaces` → `{"name":"My Research"}`; record the returned `id`.
6. `POST /api/workspaces/{workspace_id}/documents` → upload a text-based PDF.
7. `GET /api/documents/{document_id}/chunks` → returns chunk IDs, page numbers and text.
8. `POST /api/workspaces/{workspace_id}/ask` → `{"question":"Summarize the document"}`.
9. Use notes endpoints to store and retrieve notes.

## Actual frontend API contract

- `POST /api/auth/signup` / `POST /api/auth/login` / `GET /api/auth/me`
- `GET, POST /api/workspaces`
- `GET /api/workspaces/{workspace_id}/documents`
- `POST /api/workspaces/{workspace_id}/documents` (**multipart form field `file`**)
- `GET /api/documents/{document_id}/chunks`
- `GET /api/workspaces/{workspace_id}/chats`
- `GET /api/chats/{chat_id}/messages`
- `POST /api/workspaces/{workspace_id}/ask` (**JSON:** `question`, optional `chat_id`)
- `GET, POST /api/workspaces/{workspace_id}/notes`
- `DELETE /api/notes/{note_id}`

**Citation response sample:** `{ "chat_id": 1, "answer": "...", "citations": [{ "chunk_id": 12, "document_id": 2, "page": 3, "dom_id": "chunk-12", "text": "..." }] }`. Frontend can scroll to `dom_id` for the text-based viewer. Precise yellow highlights over a rendered PDF need additional text coordinates.

## Limitations and safety

This is an MVP, not a production-hardened deployment. It accepts searchable/text-based PDFs, **not scanned image-only PDFs**. Root is used only as a local learning shortcut; deployment should use a restricted database user and HTTPS. FastAPI also calls SQLAlchemy `create_all()` on startup to create missing tables as a fallback, but **you now have an actual `database/schema.sql` to import manually**. RAG validates that citation IDs were among retrieved chunks but cannot prove a cited passage semantically supports every claim. Avoid uploading confidential data to remote AI providers without permission.
