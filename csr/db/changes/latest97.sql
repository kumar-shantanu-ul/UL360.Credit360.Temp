-- Please update version.sql too -- this keeps clean builds in sync
define version=97
@update_header

VARIABLE version NUMBER
BEGIN :version := 97; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

ALTER TABLE pending_region ADD pos NUMBER(10) ;
UPDATE pending_region t
   SET pos = (SELECT rn
   				FROM (SELECT pending_region_id, ROW_NUMBER() OVER (PARTITION BY pending_dataset_id ORDER BY lower(description)) rn
	  			  	    FROM pending_region) pr
	  		   WHERE pr.pending_region_id = t.pending_region_id);
ALTER TABLE pending_region MODIFY pos NOT NULL;

@..\pending_pkg.sql
@..\pending_body.sql
@..\..\..\aspen2\tools\recompile_packages.sql

BEGIN
	UPDATE csr.version SET db_version = :version;
	COMMIT;
END;
/

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
