SET DEFINE OFF
SET DEFINE &
UPDATE chain.version SET db_version = &rap5_version WHERE part='rap5';
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
