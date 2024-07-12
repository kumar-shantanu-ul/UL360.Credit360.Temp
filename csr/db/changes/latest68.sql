-- Please update version.sql too -- this keeps clean builds in sync
define version=68
@update_header

VARIABLE version NUMBER
BEGIN :version := 68; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	


WHENEVER SQLERROR CONTINUE



alter table pending_ind add (dp number(10) null);




UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT ========== PLEASE NOW ALSO RUN LATEST67.VBS ==========
PROMPT
EXIT



@update_tail
