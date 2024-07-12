SET DEFINE OFF
SET DEFINE &
UPDATE csrimp.version SET db_version = &version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
