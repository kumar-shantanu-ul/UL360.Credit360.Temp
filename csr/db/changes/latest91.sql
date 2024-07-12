-- Please update version.sql too -- this keeps clean builds in sync
define version=91
@update_header

VARIABLE version NUMBER
BEGIN :version := 91; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE CUSTOMER ADD (STATUS NUMBER(2) DEFAULT 0 NOT NULL);

-- junk val_exclusion which isn't used any more 
ALTER TABLE VAL_EXCLUSION DROP CONSTRAINT RefIND213;
ALTER TABLE VAL_EXCLUSION DROP CONSTRAINT RefREGION214;
ALTER TABLE VAL_EXCLUSION DROP CONSTRAINT RefIND215 ;
DROP TABLE VAL_EXCLUSION PURGE;


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
