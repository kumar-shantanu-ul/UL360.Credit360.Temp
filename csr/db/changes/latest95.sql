-- Please update version.sql too -- this keeps clean builds in sync
define version=95
@update_header

VARIABLE version NUMBER
BEGIN :version := 95; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

BEGIN
	INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (17, 'Mail sent when a comment is made on an issue', NULL, '<params><param name="FROM_NAME"/><param name="FROM_EMAIL"/><param name="COMMENT"/></params>'); 
	UPDATE csr.version SET db_version = :version;
	COMMIT;
END;
/

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
