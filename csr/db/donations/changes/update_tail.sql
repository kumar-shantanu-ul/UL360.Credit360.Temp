SET DEFINE OFF
SET DEFINE &
UPDATE donations.version SET db_version = &version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
