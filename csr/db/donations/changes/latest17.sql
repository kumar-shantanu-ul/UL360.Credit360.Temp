VARIABLE version NUMBER
BEGIN :version := 17; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM donations.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/


-- has column called "column_value"
CREATE OR REPLACE TYPE T_BUDGET_NAME_TABLE AS 
  TABLE OF VARCHAR2(255);
/



UPDATE donations.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT


