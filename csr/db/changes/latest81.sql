-- Please update version.sql too -- this keeps clean builds in sync
define version=81
@update_header

VARIABLE version NUMBER
BEGIN :version := 81; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE PENDING_VAL ADD (ACTION CHAR(1) DEFAULT 'S');

DROP TYPE T_PENDING_VAL_TABLE;

CREATE OR REPLACE TYPE T_PENDING_VAL_ROW AS 
  OBJECT ( 
	PENDING_IND_ID			NUMBER(10),
	PENDING_REGION_ID		NUMBER(10),
	ROOT_REGION_ID			NUMBER(10),
	PENDING_PERIOD_ID		NUMBER(10),
	APPROVAL_STEP_ID		NUMBER(10),
	PENDING_VAL_ID			NUMBER(10),  
	ACTION      			CHAR(1)  
  );
/
CREATE OR REPLACE TYPE T_PENDING_VAL_TABLE AS 
  TABLE OF T_PENDING_VAL_ROW;
/


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
PROMPT ===============================================================
PROMPT === YOU ALSO NEED TO SVN UP AND RECOMPILE security_pkg.sql ===
PROMPT ===============================================================
PROMPT
EXIT



@update_tail
