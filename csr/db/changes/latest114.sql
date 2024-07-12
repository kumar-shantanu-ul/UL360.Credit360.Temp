-- Please update version.sql too -- this keeps clean builds in sync
define version=114
@update_header

VARIABLE version NUMBER
BEGIN :version := 114; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE DATAVIEW ADD (
  DESCRIPTION VARCHAR2(2048) NULL,
  DATAVIEW_TYPE_ID NUMBER(6) DEFAULT 1 NOT NULL,
  CONSTRAINT DATAVIEW_TYPE_CHECK CHECK (dataview_type_Id IN (1,2))
);

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
