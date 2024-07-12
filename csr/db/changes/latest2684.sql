-- Please update version.sql too -- this keeps clean builds in sync
define version=2684
@update_header

DECLARE
	v_count	number(10);
BEGIN
	SELECT COUNT(*) 
	  INTO v_count 
	  FROM all_tab_cols 
	 WHERE owner = 'CSR' 
	   AND table_name = 'FLOW_TRANSITION_ALERT' 
	   AND column_name = 'FLOW_SID';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.FLOW_TRANSITION_ALERT DROP COLUMN FLOW_SID';
	END IF;
END;
/


ALTER TABLE CSR.FLOW_ALERT_CLASS ADD HELPER_PKG VARCHAR2(64);

--set up flow alert class
BEGIN
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CMS.TAB_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'CMS';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.AUDIT_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'AUDIT';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.SECTION_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'CORPREPORTER';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.PROPERTY_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'PROPERTY';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.CAMPAIGN_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'CAMPAIGN';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.INITIATIVE_ALERT_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'INITIATIVES';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CHEM.SUBSTANCE_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'CHEMICAL';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CHAIN.SUPPLIER_FLOW_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'SUPPLIER';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.METER_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'METERREADING';
	UPDATE csr.flow_alert_class SET HELPER_PKG = 'CSR.APPROVAL_DASHBOARD_PKG' WHERE UPPER(FLOW_ALERT_CLASS) = 'APPROVALDASHBOARD';
	
		
	--WE need to find all customers/flows that have approval dashboard flow_items and update the class/add record in customer_alert_class
	FOR r IN(
		SELECT DISTINCT app_sid, flow_sid
		  FROM csr.flow_item 
		 WHERE dashboard_instance_id is not null
		 ORDER BY app_sid
	 )
	LOOP
		BEGIN
			INSERT INTO csr.customer_flow_alert_class VALUES(r.app_sid, 'approvaldashboard');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		UPDATE csr.flow
		   SET flow_alert_class = 'approvaldashboard'
		 WHERE app_sid = r.app_sid
		   AND flow_sid = r.flow_sid
		   AND flow_alert_class IS NULL;
	END LOOP;
	
END;
/

--Add new fields in figa
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD FLOW_ITEM_ID NUMBER(10);
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD FLOW_STATE_LOG_ID NUMBER(10);
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD PROCESSED_DTM DATE;
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD CREATED_DTM DATE DEFAULT SYSDATE;

--todo backup FLOW_ITEM_GENERATED_ALERT before run scripts
--update existing recs from flow_item_alert (there might be some records from incomplete cms sched tasks)
BEGIN
	security.user_pkg.logonadmin;
	
	UPDATE csr.flow_item_generated_alert figa
	   SET (flow_item_id, flow_state_log_id) = (
		SELECT flow_item_id, flow_state_log_id
		  FROM csr.flow_item_alert fia
		 WHERE fia.app_sid = figa.app_sid
		   AND fia.flow_item_alert_id = figa.flow_item_alert_id
	   );
	
END;
/

ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT MODIFY FLOW_ITEM_ALERT_ID NULL;
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT RENAME COLUMN FLOW_ITEM_ALERT_ID TO XX_FLOW_ITEM_ALERT;

ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT MODIFY FLOW_ITEM_ID NOT NULL;
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT MODIFY FLOW_STATE_LOG_ID NOT NULL;

ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD CONSTRAINT FK_FI_GEN_ALERT_FLOW_ST_LOG 
    FOREIGN KEY (APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
    REFERENCES CSR.FLOW_STATE_LOG(APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
;

CREATE INDEX CSR.IX_FI_GEN_ALERT_FLOW_ST_LOG ON CSR.FLOW_ITEM_GENERATED_ALERT(APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID);

--change slightly the logic of generating alerts records: save both user_sid and col_sid as it is easier to 
--trace that way where the alert originated from
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT DROP CONSTRAINT CHK_TO_USER_TO_COL_SIDS;

/* ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD CONSTRAINT CK_TO_USER_TO_COLUMN_SID_XOR
	CHECK ((TO_USER_SID IS NOT NULL AND TO_COLUMN_SID IS NULL) OR (TO_USER_SID IS NULL AND TO_COLUMN_SID IS NOT NULL))
; */

ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT DROP CONSTRAINT UK_FLOW_ITEM_GENERATED_ALERT DROP INDEX;
 --column sid not actually needed as we prevent duplicating alerts to users
ALTER TABLE CSR.FLOW_ITEM_GENERATED_ALERT ADD CONSTRAINT UK_FLOW_ITEM_GENERATED_ALERT
	UNIQUE (APP_SID, FLOW_TRANSITION_ALERT_ID, FROM_USER_SID, TO_USER_SID, TO_COLUMN_SID, FLOW_STATE_LOG_ID); 


--UC on flow item ids
ALTER TABLE CSR.SECTION ADD CONSTRAINT UC_SECTION_FLOW_ITEM UNIQUE (FLOW_ITEM_ID);
ALTER TABLE CSR.INITIATIVE ADD CONSTRAINT UC_INITIATIVE_FLOW_ITEM UNIQUE (FLOW_ITEM_ID);
ALTER TABLE CHEM.SUBSTANCE_REGION ADD CONSTRAINT UC_SUBSTANCE_FLOW_ITEM UNIQUE (FLOW_ITEM_ID);
--Not sure if thats correct, there are no data on live anyway
ALTER TABLE CSR.METER_READING ADD CONSTRAINT UC_METER_READING_FLOW_ITEM UNIQUE (FLOW_ITEM_ID); 
ALTER TABLE CSR.FLOW_ITEM ADD CONSTRAINT UC_FLOW_ITEM_DASHBORD_INSTANCE UNIQUE (DASHBOARD_INSTANCE_ID); 
CREATE UNIQUE INDEX CHAIN.UI_SUPPL_REL_PURCH_FLOW_ITEM ON CHAIN.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, NVL2(FLOW_ITEM_ID, FLOW_ITEM_ID, SUPPLIER_COMPANY_SID)); 

CREATE OR REPLACE VIEW CSR.v$flow_item_gen_alert AS
	SELECT fta.flow_transition_alert_id, fta.customer_alert_type_id, fta.helper_sp,
		flsf.flow_state_id from_state_id, flsf.label from_state_label,
		flst.flow_state_id to_state_id, flst.label to_state_label, 
		fsl.flow_state_log_Id, fsl.set_dtm, fsl.set_by_user_sid, fsl.comment_text,
		cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
		cut.csr_user_sid to_user_sid, cut.full_name to_full_name,
		cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
		fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id,
		fi.survey_response_id, fi.dashboard_instance_id, fta.to_initiator, fta.flow_alert_helper,
		figa.to_column_sid, figa.flow_item_generated_alert_id, figa.processed_dtm, figa.created_dtm, 
		cat.is_batched, ftacc.alert_manager_flag, fta.flow_state_transition_id
	  FROM flow_item_generated_alert figa 
	  JOIN flow_state_log fsl ON figa.flow_state_log_id = fsl.flow_state_log_id AND figa.flow_item_id = fsl.flow_item_id AND figa.app_sid = fsl.app_sid
	  JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid 
	  JOIN flow_item fi ON figa.flow_item_id = fi.flow_item_id AND figa.app_sid = fi.app_sid
	  JOIN flow_transition_alert fta ON figa.flow_transition_alert_id = fta.flow_transition_alert_id AND figa.app_sid = fta.app_sid            
	  JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
	  JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
	  JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid
	  LEFT JOIN cms_alert_type cat ON  fta.customer_alert_type_id = cat.customer_alert_type_id
	  LEFT JOIN flow_transition_alert_cms_col ftacc ON figa.flow_transition_alert_id = ftacc.flow_transition_alert_id AND figa.to_column_sid = ftacc.column_sid
	  LEFT JOIN csr_user cut ON figa.to_user_sid = cut.csr_user_sid AND figa.app_sid = cut.app_sid
	 WHERE fta.deleted = 0;
	   
CREATE OR REPLACE VIEW CSR.v$open_flow_item_gen_alert AS
	SELECT flow_transition_alert_id, customer_alert_type_id, helper_sp,
		from_state_id, from_state_label,
		to_state_id, to_state_label, 
		flow_state_log_Id, set_dtm, set_by_user_sid, comment_text,
		set_by_full_name, set_by_email, set_by_user_name, 
		to_user_sid, to_full_name,
		to_email, to_user_name, to_friendly_name,
		app_sid, flow_item_id, flow_sid, current_state_id,
		survey_response_id, dashboard_instance_id, to_initiator, flow_alert_helper,
		to_column_sid, flow_item_generated_alert_id,
		is_batched, alert_manager_flag, created_dtm, flow_state_transition_id
	  FROM csr.v$flow_item_gen_alert 
	 WHERE processed_dtm IS NULL;


GRANT SELECT ON csr.v$open_flow_item_gen_alert TO CHAIN;
GRANT SELECT ON csr.flow_item TO CHAIN;
GRANT SELECT ON csr.flow_transition_alert TO CHAIN;
GRANT SELECT ON csr.flow_involvement_type TO CHAIN;
GRANT SELECT ON csr.flow_state_log TO CHAIN;
GRANT SELECT, INSERT ON csr.flow_item_generated_alert TO CHAIN;
GRANT SELECT ON csr.flow_item_gen_alert_id_seq TO CHAIN;

GRANT SELECT, INSERT, UPDATE, DELETE ON csr.flow_item_generated_alert TO CMS;

GRANT SELECT ON csr.v$open_flow_item_gen_alert TO CHEM;

GRANT EXECUTE ON chem.substance_pkg TO CSR;
GRANT EXECUTE ON chain.supplier_flow_pkg TO CSR;

ALTER TABLE CSR.FLOW_ITEM_ALERT RENAME TO XX_FLOW_ITEM_ALERT;

DROP VIEW CSR.V$OPEN_FLOW_ITEM_ALERT;
DROP VIEW CSR.V$FLOW_ITEM_ALERT;

GRANT EXECUTE ON csr.alert_pkg to cms;

--csrexp/imp
DROP TABLE csrimp.flow_item_alert;
CREATE TABLE CSRIMP.FLOW_ITEM_GENERATED_ALERT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_ITEM_GENERATED_ALERT_ID	NUMBER(10, 0)    NOT NULL,
    FLOW_ITEM_ID               		NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_LOG_ID           	NUMBER(10, 0)    NOT NULL,
    FLOW_TRANSITION_ALERT_ID    	NUMBER(10, 0)    NOT NULL,
    PROCESSED_DTM               	DATE,
    CREATED_DTM		               	DATE,
    FROM_USER_SID	               	NUMBER(10, 0),
    TO_USER_SID		               	NUMBER(10, 0),
    TO_COLUMN_SID	               	NUMBER(10, 0),
    CONSTRAINT PK_FLOW_ITEM_GENERATED_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_ITEM_GENERATED_ALERT_ID),
    CONSTRAINT FK_FLOW_ITEM_GEN_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	DBMS_RLS.ADD_POLICY(
		object_schema   => 'CSRIMP',
		object_name     => 'FLOW_ITEM_GENERATED_ALERT',
		policy_name     => 'FLOW_ITEM_GEN_ALERT_POLICY',
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check    => true,
		policy_type     => dbms_rls.context_sensitive );
	DBMS_OUTPUT.PUT_LINE('Policy added to FLOW_ITEM_GENERATED_ALERT');
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists for FLOW_ITEM_GENERATED_ALERT');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied for FLOW_ITEM_GENERATED_ALERT as feature not enabled');
END;
/

GRANT SELECT,INSERT,UPDATE,DELETE ON CSRIMP.FLOW_ITEM_GENERATED_ALERT TO WEB_USER;
GRANT SELECT ON csr.flow_item_gen_alert_id_seq to csrimp;
GRANT INSERT ON csr.flow_item_generated_alert to csrimp;

@../../../aspen2/cms/db/tab_pkg
@../schema_pkg
@../flow_pkg
@../audit_pkg
@../campaign_pkg
@../section_pkg
@../property_pkg
@../quick_survey_pkg
@../meter_pkg
@../approval_dashboard_pkg
@../initiative_alert_pkg
@../chain/supplier_flow_pkg
@../chem/substance_pkg
@../enable_pkg

@../../../aspen2/cms/db/tab_body
@../csr_app_body
@../flow_body
@../alert_body
@../audit_body
@../quick_survey_body
@../campaign_body
@../section_body
@../meter_body
@../property_body
@../initiative_alert_body
@../initiative_metric_body
@../approval_dashboard_body
@../chain/supplier_flow_body
@../chem/substance_body
@../schema_body
@../csrimp/imp_body


@update_tail
