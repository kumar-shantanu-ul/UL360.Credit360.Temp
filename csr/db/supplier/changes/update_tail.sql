SET DEFINE OFF
SET DEFINE &

BEGIN
    IF &version <= 73 THEN
        EXECUTE IMMEDIATE 'UPDATE version SET db_version = &version';
    ELSE
        EXECUTE IMMEDIATE 'UPDATE version SET db_version = &version WHERE part = ''generic''';
    END IF;
END;
/

COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
