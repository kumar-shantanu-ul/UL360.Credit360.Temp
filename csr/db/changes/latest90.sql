-- Please update version.sql too -- this keeps clean builds in sync
define version=90
@update_header

VARIABLE version NUMBER
BEGIN :version := 90; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

CREATE INDEX IDX_AUDIT_LOG_CSR_ROOT_SID ON AUDIT_LOG(CSR_ROOT_SID);
CREATE INDEX IDX_AUDIT_LOG_OBJECT_SID ON AUDIT_LOG(OBJECT_SID);
CREATE INDEX IDX_AUDIT_LOG_USER_SID ON AUDIT_LOG(USER_SID);

INSERT INTO AUDIT_TYPE ( AUDIT_TYPE_ID, LABEL ) VALUES (7, 'Logon failed');


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
