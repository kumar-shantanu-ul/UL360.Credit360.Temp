-- Please update version.sql too -- this keeps clean builds in sync
define version=67
@update_header

VARIABLE version NUMBER
BEGIN :version := 67; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	


WHENEVER SQLERROR CONTINUE



alter table pending_ind add (INFO_XML CLOB);
alter table approval_Step_user modify fallback_user_id null;

ALTER TABLE CUSTOMER ADD (   
    IND_INFO_XML_FIELDS       CLOB,
    REGION_INFO_XML_FIELDS    CLOB,
    USER_INFO_XML_FIELDS      CLOB);



UPDATE version SET db_version = :version;
COMMIT;
PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT ========== PLEASE NOW ALSO RUN LATEST67.VBS ==========
PROMPT
EXIT



@update_tail
