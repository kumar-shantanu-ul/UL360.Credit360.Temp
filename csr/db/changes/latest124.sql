-- Please update version.sql too -- this keeps clean builds in sync
define version=124
@update_header

VARIABLE version NUMBER
BEGIN :version := 124; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

PROMPT > Enter service name (e.g. ASPEN):
connect security/security@&&1
grant change notification to csr;

connect csr/csr@&&1
UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
