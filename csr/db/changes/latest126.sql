-- Please update version.sql too -- this keeps clean builds in sync
define version=126
@update_header

VARIABLE version NUMBER
BEGIN :version := 126; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

drop index IX_REGION_BACK_LINK;
CREATE INDEX IX_REGION_BACK_LINK ON "CSR"."REGION" (csr_root_sid, LINK_TO_REGION_SID, REGION_SID)
  TABLESPACE "INDX" ;

UPDATE version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
 

@update_tail
