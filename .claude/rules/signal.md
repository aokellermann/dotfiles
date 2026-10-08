# Signal message history (read-only)

The user's Signal Desktop is the **Flatpak** `org.signal.Signal` (native `~/.config/Signal` is a stale copy from
2026-04). Its history is a SQLCipher DB at `~/.var/app/org.signal.Signal/config/Signal/sql/db.sqlite`; the key is in
`config.json` (`encryptedKey`, Electron safeStorage `v11`), decryptable with the libsecret entry
`application=Signal` (schema `chrome_libsecret_os_crypt_password_v2`). Worked out 2026-09-23.

- Helper: `~/.local/share/signal-tools/signaldb.py` — decrypts the key and opens `db.sqlite` in the **current
  directory**; copy the DB (`cp .../sql/db.sqlite* <scratchpad>/`) first, never open the live file while Signal runs.
  Run with `uv run --with sqlcipher3-binary --with cryptography python signaldb.py "<sql>"`, or `exec` the part before
  `if __name__` and call `q(sql, *params)`.
- Decryption gotcha: Chromium on Linux uses PBKDF2-SHA1 with **1 iteration** (1003 is macOS), salt `saltysalt`,
  AES-128-CBC, IV = 16 spaces; the key is the 64-hex string, opened via `PRAGMA key = "x'<hex>'"`.
- Schema: `messages` (`sent_at` ms, `type` incoming/outgoing, `body`, `conversationId`, `sourceServiceId`), `conversations`
  (`name` for groups, `profileFullName`/`e164` for people, `serviceId`). Sender name of a group message =
  `conversations.serviceId = messages.sourceServiceId`. Search with `body like '%term%'` (or `messages_fts`).
- `signal-cli` (linked to the user's own number) is also linked but has no persistent history; use the Desktop DB for reads.
- Read-only by convention; treat the DB copy like a credential and delete it from the scratchpad when done.
- **Attachments** (worked out 2026-09-25): metadata is in `message_attachments` (join `messageId` = `messages.id`;
  `fileName`, `contentType`, `size`, `path`, `localKey`, `plaintextHash`). The file at
  `~/.var/app/org.signal.Signal/config/Signal/attachments.noindex/<path>` is encrypted with **`localKey`** (base64, 64
  bytes: AES-256 key ‖ HMAC-SHA256 key), *not* the `key` column (that is the transport key). Layout: IV(16) ‖
  AES-CBC ciphertext ‖ HMAC(32) over IV‖ciphertext; the plaintext is padded, so truncate to `size` and check
  sha256 against `plaintextHash`. ~15 lines with `cryptography`; see the 2026-09-25 csai session.
