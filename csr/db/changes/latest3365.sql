define version=3365
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE GLOBAL TEMPORARY TABLE CSR.TT_ISSUES_DUE (
	APP_SID					NUMBER(10)		NOT NULL,
	ISSUE_ID				NUMBER(10)		NOT NULL,
	DUE_DTM					DATE,
	EMAIL_INVOLVED_ROLES	NUMBER(1),		
	email_involved_users	NUMBER(1),		
	assigned_to_user_sid	NUMBER(10),		
	region_sid				NUMBER(10),		
	region_2_sid			NUMBER(10),		
	issue_priority_id		NUMBER(10),		
	alert_pending_due_days	NUMBER(10),		
	issue_type				VARCHAR2(255),		
	issue_label				VARCHAR2(2048),		
	issue_ref				NUMBER(10),			
	is_critical				NUMBER(1),		
	raised_dtm				DATE,		
	closed_dtm				DATE,		
	resolved_dtm			DATE,		
	rejected_dtm			DATE,		
	assigned_to_role_sid	NUMBER(10)
)ON COMMIT DELETE ROWS;
CREATE GLOBAL TEMPORARY TABLE CSR.TT_ISSUES_OVERDUE (
	APP_SID					NUMBER(10)		NOT NULL,
	ISSUE_ID				NUMBER(10)		NOT NULL,
	DUE_DTM					DATE,
	EMAIL_INVOLVED_ROLES	NUMBER(1),		
	email_involved_users	NUMBER(1),		
	assigned_to_user_sid	NUMBER(10),		
	region_sid				NUMBER(10),		
	region_2_sid			NUMBER(10),		
	issue_priority_id		NUMBER(10),		
	alert_overdue_days		NUMBER(10),		
	issue_type				VARCHAR2(255),		
	issue_label				VARCHAR2(2048),		
	issue_ref				NUMBER(10),		
	is_critical				NUMBER(1),		
	raised_dtm				DATE,		
	closed_dtm				DATE,		
	resolved_dtm			DATE,		
	rejected_dtm			DATE,		
	assigned_to_role_sid	NUMBER(10)
)ON COMMIT DELETE ROWS;
CREATE GLOBAL TEMPORARY TABLE CSR.TT_ISSUE_USER (
	APP_SID					NUMBER(10)		NOT NULL,
	ISSUE_ID				NUMBER(10)		NOT NULL,
	USER_SID				NUMBER(10)		NOT NULL
)ON COMMIT DELETE ROWS;


ALTER TABLE csr.scheduled_task_stat ADD run_guid VARCHAR2(38);










INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg)
VALUES ('disclosure', 'Disclosure', 'csr.disclosure_flow_helper_pkg');
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg)
VALUES ('disclosuredelegation', 'Disclosure Delegation', 'csr.disclosure_flow_helper_pkg');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
VALUES (38, 'disclosuredelegation', 'Promoted to Approved');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
VALUES (39, 'disclosure', 'Promoted to Submission');
DELETE FROM csr.flow_state_nature
 WHERE flow_state_nature_id = 38;
UPDATE csr.flow_alert_class
   SET helper_pkg = 'csr.flow_helper_pkg'
 WHERE flow_alert_class LIKE 'disclosure%';
UPDATE csr.flow_alert_class
   SET flow_alert_class = 'disclosureassignment',
	   label = 'Disclosure Assignment'
 WHERE flow_alert_class = 'disclosuredelegation';
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
VALUES (38, 'disclosureassignment', 'Promoted to Approved');
DROP TABLE CSR.MANANGED_CONTENT_UNPACKAGE_LOG_RUN CASCADE CONSTRAINTS;
CREATE TABLE CSR.MANAGED_CONTENT_UNPACKAGE_LOG_RUN (
	APP_SID		            NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	MESSAGE_ID 	            NUMBER(10, 0) NOT NULL,
	RUN_ID 		            NUMBER(10, 0) NOT NULL,
	SEVERITY            	VARCHAR2(1) NOT NULL,
	MSG_DTM		            DATE NOT NULL,
	MESSAGE		            CLOB NOT NULL,
    CONSTRAINT PK_MANAGED_CONTENT_UNPKG_LOG_RUN PRIMARY KEY (APP_SID, RUN_ID, MESSAGE_ID),
    CONSTRAINT CK_MANAGED_CONTENT_MSG_SEV CHECK (SEVERITY IN ('E','C','I','D'))
)
;


DECLARE
	v_count NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM all_objects
	 WHERE owner = 'CSR'
	   AND object_type = 'PACKAGE'
	   AND object_name = 'DISCLOSURE_FLOW_HELPER_PKG';
	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'DROP PACKAGE CSR.DISCLOSURE_FLOW_HELPER_PKG';
	END IF;
END;
/




@..\flow_helper_pkg
@..\indicator_pkg
@..\managed_content_pkg
@..\scheduled_task_pkg


@..\enable_body
@..\flow_helper_body
@..\indicator_body
@..\managed_content_body
@..\audit_body
@..\issue_body
@..\scheduled_task_body
@..\util_script_body



@update_tail
