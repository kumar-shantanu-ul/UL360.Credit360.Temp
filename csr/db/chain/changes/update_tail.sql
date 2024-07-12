PROMPT >> Recompiling packages...
@recompile_packages

SET DEFINE OFF
SET DEFINE &
BEGIN
	IF &version < 52 THEN
		UPDATE chain.version SET db_version = &version;
	ELSE
		UPDATE chain.version SET db_version = &version WHERE part='trunk';
	END IF;
	COMMIT;
END;
/

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
