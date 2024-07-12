-- Please update version.sql too -- this keeps clean builds in sync
define version=87
@update_header

VARIABLE version NUMBER
BEGIN :version := 87; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

alter table pending_val_log add (
    PARAM_1               VARCHAR2(2048),
    PARAM_2               VARCHAR2(2048),
    PARAM_3               VARCHAR2(2048)
);


INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (16, 'Mail sent to data provider when final approval occurs', NULL, '<params><param name="FROM_NAME"/><param name="FROM_EMAIL"/><param name="LABEL"/><param name="TO_NAME"/><param name="TO_FRIENDLY_NAME"/><param name="TO_EMAIL"/></params>'); 
       

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
