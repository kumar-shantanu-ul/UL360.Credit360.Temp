-- Please update version.sql too -- this keeps clean builds in sync
define version=118
@update_header

VARIABLE version NUMBER
BEGIN :version := 118; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE CSR.CUSTOMER
MODIFY(LOCK_START_DTM  DEFAULT TO_DATE('1 jan 1980', 'DD MON yyyy'));

ALTER TABLE CSR.CUSTOMER
MODIFY(LOCK_END_DTM  DEFAULT TO_DATE('1 jan 1980', 'DD MON yyyy'));


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
