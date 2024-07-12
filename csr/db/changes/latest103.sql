-- Please update version.sql too -- this keeps clean builds in sync
define version=103
@update_header

VARIABLE version NUMBER
BEGIN :version := 103; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

CREATE OR REPLACE VIEW AUDIT_VAL_LOG AS	   
	SELECT CHANGED_DTM AUDIT_DATE, R.CSR_ROOT_SID, 6 AUDIT_TYPE_ID, vc.IND_SID OBJECT_SID, CHANGED_BY_SID USER_SID,
	 'Set "{0}" ("{1}") to {2}: '||REASON DESCRIPTION, I.DESCRIPTION PARAM_1, R.DESCRIPTION PARAM_2, VAL_NUMBER PARAM_3
	FROM VAL_CHANGE VC, REGION R, IND I
	WHERE VC.REGION_SID = R.REGION_SID
	   AND VC.IND_SID = I.IND_SID;


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
