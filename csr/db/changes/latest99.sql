-- Please update version.sql too -- this keeps clean builds in sync
define version=99
@update_header

VARIABLE version NUMBER
BEGIN :version := 99; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

alter table customer add raise_split_deleg_alerts number(1) default 0 not null;

@..\sheet_body.sql

BEGIN
	update customer set raise_split_deleg_alerts=1 where host='cairnindia.credit360.com';
	UPDATE csr.version SET db_version = :version;
	COMMIT;
END;
/

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
