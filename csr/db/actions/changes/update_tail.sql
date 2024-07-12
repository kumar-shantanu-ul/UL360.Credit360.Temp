SET DEFINE OFF
SET DEFINE &
UPDATE actions.version SET db_version = &version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
