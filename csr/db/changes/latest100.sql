-- Please update version.sql too -- this keeps clean builds in sync
define version=100
@update_header

VARIABLE version NUMBER
BEGIN :version := 100; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

alter table range_ind_member add measure_conversion_id number(10) references measure_conversion(measure_conversion_id);

BEGIN
	UPDATE csr.version SET db_version = :version;
	COMMIT;
END;
/

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
