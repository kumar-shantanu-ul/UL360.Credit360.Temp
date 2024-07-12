-- Please update version.sql too -- this keeps clean builds in sync
define version=84
@update_header

VARIABLE version NUMBER
BEGIN :version := 84; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

alter table alert_type add (
    PARENT_ALERT_TYPE_ID    NUMBER(10, 0)
);

ALTER TABLE ALERT_TYPE ADD CONSTRAINT RefALERT_TYPE567 
    FOREIGN KEY (PARENT_ALERT_TYPE_ID)
    REFERENCES ALERT_TYPE(ALERT_TYPE_ID)
;

alter table alert disable constraint REFALERT_TYPE186;
alter table alert_template disable constraint REFALERT_TYPE188;

delete from alert_type;

BEGIN
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 1, 'New user', 'alert_pkg.GetAlerts_NewUser'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 2, 'New delegation', 'alert_pkg.GetAlerts_NewDelegation'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 3, 'Delegation data overdue', 'alert_pkg.GetAlerts_DelegDataOverdue'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 4, 'Delegation state changed', 'alert_pkg.GetAlerts_DelegStateChange');  
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 5, 'Delegation data reminder', 'alert_pkg.GetAlerts_DelegDataRemind');   
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP ) VALUES ( 6, 'Consolidated alert', NULL);  

INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (9, 'Mail sent when new approval step form created', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="LABEL"/><param name="FROM_EMAIL"/></params>'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (10, 'Mail sent thanking user for submission of data', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="LABEL"/><param name="TO_NAMES"/></params>'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (11, 'Mail sent to user when their data is rejected', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="LABEL"/><param name="DUE_DTM"/><param name="FROM_NAME"/><param name="FROM_EMAIL"/></params>'); 
INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (12, 'Mail sent to subdelegee when sub-delegation takes place', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="FROM_NAME"/><param name="FROM_EMAIL"/><param name="LABEL"/></params>'); 

INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, PARENT_ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (13,10, 'Mail sent thanking user for submitting to approval step owner', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="LABEL"/><param name="TO_NAMES"/></params>'); 

INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, PARENT_ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (14,11, 'Mail sent when approval step owner rejects', NULL, '<params><param name="EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="LABEL"/><param name="DUE_DTM"/><param name="FROM_NAME"/><param name="FROM_FRIENDLY_NAME"/><param name="FROM_EMAIL"/></params>'); 

INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (15, 'Mail sent to approver when a new submission is made', NULL, '<params><param name="FROM_NAME"/><param name="FROM_EMAIL"/><param name="LABEL"/><param name="TO_NAME"/><param name="TO_EMAIL"/></params>'); 

END;
/

BEGIN
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="USER_NAME"/></params>' WHERE alert_type_id = 1;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="DELEGATOR_FULL_NAME"/><param name="DELEGATOR_EMAIL"/><param name="USER_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/><param name="DELEGATION_SID"/><param name="SHEET_ID"/></params>' WHERE alert_type_id = 2;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL  "/><param name="USER_NAME"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/></params>' WHERE alert_type_id = 3;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FROM_NAME"/><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="FROM_EMAIL"/><param name="TO_NAME"/><param name="TO_EMAIL"/><param name="DESCRIPTION"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/><param name="NOTE"/></params>' WHERE alert_type_id = 4;
UPDATE ALERT_TYPE SET params_xml ='<params><param name="FULL_NAME"/><param name="FRIENDLY_NAME"/><param name="EMAIL"/><param name="DELEGATION_NAME"/><param name="SUBMISSION_DTM_FMT"/></params>' WHERE alert_type_id = 5;
END;
/

alter table alert enable constraint REFALERT_TYPE186;
alter table alert_template enable constraint REFALERT_TYPE188;




UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
