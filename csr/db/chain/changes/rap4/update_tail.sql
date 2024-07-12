SET DEFINE OFF
SET DEFINE &
UPDATE chain.version SET db_version = &rap4_version WHERE part='rap4';
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
