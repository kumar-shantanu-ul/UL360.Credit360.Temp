-- Please update version.sql too -- this keeps clean builds in sync
define version=85
@update_header

VARIABLE version NUMBER
BEGIN :version := 85; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

alter table IMP_VAL modify VAL number(24,10);
alter table IMP_VAL modify CONVERSION_FACTOR number(24,10);

alter table MEASURE_CONVERSION modify CONVERSION_FACTOR number(24,10);
alter table MEASURE_CONVERSION_PERIOD modify CONVERSION_FACTOR number(24,10);

alter table SHEET_VALUE modify VAL_NUMBER number(24,10);
alter table SHEET_VALUE modify ENTRY_VAL_NUMBER number(24,10);
alter table SHEET_VALUE_CHANGE modify VAL_NUMBER number(24,10);
alter table SHEET_VALUE_CHANGE modify ENTRY_VAL_NUMBER number(24,10);

alter table VAL modify VAL_NUMBER number(24,10);
alter table VAL modify ENTRY_VAL_NUMBER number(24,10);

alter table VAL_CHANGE modify VAL_NUMBER number(24,10);
alter table VAL_CHANGE modify ENTRY_VAL_NUMBER number(24,10);


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
