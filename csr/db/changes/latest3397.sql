define version=3397
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



ALTER TABLE csr.period_set
ADD CONSTRAINT uk_period_set_label UNIQUE (app_sid, label);
drop type CSR.T_FLOW_ALERT_TABLE;
drop type CSR.T_FLOW_ALERT_ROW;
CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_ROW AS
  OBJECT (
		APP_SID							NUMBER(10),
		FLOW_STATE_TRANSITION_ID		NUMBER(10),
		FLOW_ITEM_GENERATED_ALERT_ID	NUMBER(10),
		CUSTOMER_ALERT_TYPE_ID			NUMBER(10),
		FLOW_STATE_LOG_ID				NUMBER(10),
		FROM_STATE_LABEL				VARCHAR2(255),
		TO_STATE_LABEL					VARCHAR2(255),
		SET_BY_USER_SID					NUMBER(10),
		SET_BY_EMAIL					VARCHAR2(256),
		SET_BY_FULL_NAME				VARCHAR2(256),
		SET_BY_USER_NAME				VARCHAR2(256),
		TO_USER_SID						NUMBER(10),
		FLOW_ALERT_HELPER				VARCHAR2(256),
		TO_USER_NAME					VARCHAR2(256),
		TO_FULL_NAME					VARCHAR2(256),
		TO_EMAIL						VARCHAR2(256),
		TO_FRIENDLY_NAME				VARCHAR2(255),
		TO_INITIATOR					NUMBER(1),
		FLOW_ITEM_ID					NUMBER(10),
		FLOW_TRANSITION_ALERT_ID		NUMBER(10),
		COMMENT_TEXT					CLOB,
		SET_DTM							DATE
  );
/
CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_TABLE AS 
  TABLE OF CSR.T_FLOW_ALERT_ROW;
/
ALTER TABLE csr.customer ADD show_feedback_fab NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csr.customer ADD CONSTRAINT CK_SHOW_FEEDBACK_FAB CHECK (SHOW_FEEDBACK_FAB IN (0,1));
ALTER TABLE csrimp.customer ADD show_feedback_fab NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD CONSTRAINT CK_SHOW_FEEDBACK_FAB CHECK (SHOW_FEEDBACK_FAB IN (0,1));
INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES (71, 'Enable Feedback', 'Displays a feedback floating action button on the right side of screen to allow users to provide feedback. (LOGOUT REQUIRED)', 'EnableFeedbackFAB', null);
INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES (72, 'Disable Feedback', 'Removes the feedback floating action button on the right side of screen. (LOGOUT REQUIRED)', 'DisableFeedbackFAB', null);


BEGIN
	FOR r IN (SELECT NULL FROM all_users WHERE username = 'SURVEYS')
	LOOP
		EXECUTE IMMEDIATE 'GRANT EXECUTE ON csr.t_flow_alert_table TO SURVEYS';
	END LOOP;
END;
/








INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES(4001, 'disclosureassignment', 'Disclosure assignment', 0 /*Specific*/, 1 /*READ*/);
DELETE FROM csr.flow_capability WHERE flow_capability_id = 4001;
UPDATE csr.flow_alert_class
   SET flow_alert_class = 'disclosureassignment',
	   label = 'Disclosure assignment'
 WHERE flow_alert_class = 'disclosureassignments';
UPDATE csr.flow_state_nature
   SET flow_alert_class = 'disclosureassignment'
 WHERE flow_state_nature_id = 38;
INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES(4001, 'disclosureassignment', 'Disclosure assignment', 0 /*Specific*/, 1 /*READ*/);






@..\period_pkg
@..\util_script_pkg


@..\period_body
@..\enable_body
@..\campaigns\campaign_body
@..\flow_body
@..\automated_export_body
@..\schema_body
@..\customer_body
@..\util_script_body
@..\csrimp\imp_body



@update_tail
