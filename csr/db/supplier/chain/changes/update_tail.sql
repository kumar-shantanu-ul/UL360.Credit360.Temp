SET DEFINE OFF
SET DEFINE &
UPDATE version SET db_version = &version WHERE part='chain';
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
