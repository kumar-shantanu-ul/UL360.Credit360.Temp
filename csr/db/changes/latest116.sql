-- Please update version.sql too -- this keeps clean builds in sync
define version=116
@update_header

VARIABLE version NUMBER
BEGIN :version := 116; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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
	SELECT db_version INTO v_version FROM security.version;
	IF v_version < 4 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A *** SECURITY *** DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

CREATE GLOBAL TEMPORARY TABLE REGION_LIST
(
	REGION_SID		NUMBER(10)	NOT NULL,
	POS			NUMBER(10)
) ON COMMIT DELETE ROWS;

UPDATE csr.version SET db_version = :version;
COMMIT;

@..\sheet_pkg.sql
@..\sheet_body.sql
@..\region_pkg.sql
@..\region_body.sql
@..\indicator_pkg.sql
@..\indicator_body.sql
@..\..\..\aspen2\tools\recompile_packages.sql

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
