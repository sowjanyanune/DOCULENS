-- DOCULENS / PERSON 2: MySQL schema
-- Open THIS file in MySQL Workbench while signed in with your local root connection.
-- Click the lightning bolt to run the entire script. Safe to re-run (does not delete data).
CREATE DATABASE IF NOT EXISTS doculens
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE doculens;

CREATE TABLE IF NOT EXISTS users (
  id INT NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  PRIMARY KEY (id), UNIQUE KEY ix_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS workspaces (
  id INT NOT NULL AUTO_INCREMENT,
  owner_id INT NOT NULL,
  name VARCHAR(120) NOT NULL,
  PRIMARY KEY (id), KEY ix_workspaces_owner_id (owner_id),
  CONSTRAINT fk_workspaces_owner FOREIGN KEY (owner_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS documents (
  id INT NOT NULL AUTO_INCREMENT,
  workspace_id INT NOT NULL,
  filename VARCHAR(255) NOT NULL,
  storage_path VARCHAR(500) NOT NULL,
  pages INT NOT NULL,
  PRIMARY KEY (id), KEY ix_documents_workspace_id (workspace_id),
  CONSTRAINT fk_documents_workspace FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS chunks (
  id INT NOT NULL AUTO_INCREMENT,
  document_id INT NOT NULL,
  page INT NOT NULL,
  ordinal INT NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (id), KEY ix_chunks_document_id (document_id),
  CONSTRAINT fk_chunks_document FOREIGN KEY (document_id) REFERENCES documents(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS chats (
  id INT NOT NULL AUTO_INCREMENT,
  workspace_id INT NOT NULL,
  created_at DATETIME NOT NULL,
  PRIMARY KEY (id), KEY ix_chats_workspace_id (workspace_id),
  CONSTRAINT fk_chats_workspace FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS messages (
  id INT NOT NULL AUTO_INCREMENT,
  chat_id INT NOT NULL,
  role VARCHAR(15) NOT NULL,
  content TEXT NOT NULL,
  citations_json TEXT NOT NULL,
  PRIMARY KEY (id), KEY ix_messages_chat_id (chat_id),
  CONSTRAINT fk_messages_chat FOREIGN KEY (chat_id) REFERENCES chats(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notes (
  id INT NOT NULL AUTO_INCREMENT,
  workspace_id INT NOT NULL,
  text TEXT NOT NULL,
  source_message_id INT NULL,
  PRIMARY KEY (id), KEY ix_notes_workspace_id (workspace_id),
  KEY ix_notes_source_message_id (source_message_id),
  CONSTRAINT fk_notes_workspace FOREIGN KEY (workspace_id) REFERENCES workspaces(id),
  CONSTRAINT fk_notes_message FOREIGN KEY (source_message_id) REFERENCES messages(id)
) ENGINE=InnoDB;

SHOW TABLES;
