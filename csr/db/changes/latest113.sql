-- Please update version.sql too -- this keeps clean builds in sync
define version=113
@update_header

VARIABLE version NUMBER
BEGIN :version := 113; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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


begin
update sheet_action set description='Merged, and changes made afterwards - will need remerge' where sheet_action_id = 12;
update sheet_action set description='Pending approval - changes made after submission' where sheet_action_id = 11;
update sheet_action set description='Data being entered' where sheet_action_id = 10;
update sheet_action set description='Approved, and changes made afterwards' where sheet_action_id = 6;
end;
/



-- this was too short for some indicator names (for Linde)
alter table ind modify description varchar2(1023);
alter table imp_ind modify description varchar2(1023);
alter table delegation_ind modify description varchar2(1023);
alter table range_ind_member modify description varchar2(1023);



BEGIN
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL  "/><param name="USER_NAME"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/><param name="SHEET_URL"/></params>' WHERE alert_type_id = 3;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FROM_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="FROM_EMAIL"/><param name="TO_NAME"/><param name="TO_EMAIL"/><param name="DESCRIPTION"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/><param name="SHEET_URL"/><param name="NOTE"/></params>' WHERE alert_type_id = 4;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="DELEGATION_NAME"/><param name="SHEET_URL"/><param name="SUBMISSION_DTM_FMT"/></params>' WHERE alert_type_id = 5;
END;
/

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
