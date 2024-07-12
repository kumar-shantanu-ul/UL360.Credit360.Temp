-- Please update version.sql too -- this keeps clean builds in sync
define version=2728
@update_header

BEGIN
	-- clean all sessions as we adding NOT NULL columns
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
END;
/

-- *** DDL ***
-- Create tables
-- mapping tables
CREATE TABLE csrimp.map_tpl_rep_tag_appr_note (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_rep_tag_appr_note_id		NUMBER(10)	NOT NULL,
	new_tpl_rep_tag_appr_note_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_rep_tag_appr_note primary key (csrimp_session_id, old_tpl_rep_tag_appr_note_id) USING INDEX,
	CONSTRAINT uk_map_tpl_rep_tag_appr_note unique (csrimp_session_id, new_tpl_rep_tag_appr_note_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_APPR_N_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_appr_matr (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_rep_tag_appr_matr_id		NUMBER(10)	NOT NULL,
	new_tpl_rep_tag_appr_matr_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_rep_tag_appr_matr primary key (csrimp_session_id, old_tpl_rep_tag_appr_matr_id) USING INDEX,
	CONSTRAINT uk_map_tpl_rep_tag_appr_matr unique (csrimp_session_id, new_tpl_rep_tag_appr_matr_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_APPR_M_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_appr_dash_val (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_approval_dashboard_val_id		NUMBER(10)	NOT NULL,
	new_approval_dashboard_val_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_approval_dash_val primary key (csrimp_session_id, old_approval_dashboard_val_id) USING INDEX,
	CONSTRAINT uk_map_approval_dash_val unique (csrimp_session_id, new_approval_dashboard_val_id) USING INDEX,
    CONSTRAINT fk_map_approval_dash_val_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_appr_dash_val_src (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_approval_dash_val_src_id		NUMBER(10)	NOT NULL,
	new_approval_dash_val_src_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_appr_dash_val_src primary key (csrimp_session_id, old_approval_dash_val_src_id) USING INDEX,
	CONSTRAINT uk_map_appr_dash_val_src unique (csrimp_session_id, new_approval_dash_val_src_id) USING INDEX,
    CONSTRAINT fk_map_appr_dash_val_src_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- data tables
CREATE TABLE CSRIMP.APPROVAL_DASHBOARD_VAL(
	CSRIMP_SESSION_ID			 NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    APPROVAL_DASHBOARD_VAL_ID    NUMBER(10, 0)     NOT NULL,
    APPROVAL_DASHBOARD_SID       NUMBER(10, 0)     NOT NULL,
    DASHBOARD_INSTANCE_ID        NUMBER(10, 0)     NOT NULL,
    IND_SID                      NUMBER(10, 0)     NOT NULL,
    START_DTM                    DATE              NOT NULL,
    END_DTM                      DATE              NOT NULL,
    VAL_NUMBER                   NUMBER(24, 10)    NOT NULL,
	YTD_VAL_NUMBER               NUMBER(24, 10)    NOT NULL,
	NOTE						 VARCHAR2(2048),
	NOTE_ADDED_BY_SID			 NUMBER(10),
	NOTE_ADDED_DTM				 DATE,
	IS_ESTIMATED_DATA 			 NUMBER(1)		   NOT NULL,
    CONSTRAINT PK_APPROVAL_DASHBOARD_VAL PRIMARY KEY (CSRIMP_SESSION_ID, APPROVAL_DASHBOARD_VAL_ID),
	CONSTRAINT FK_APPROVAL_DASHBOARD_VAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.APPROVAL_DASHBOARD_IND(
    CSRIMP_SESSION_ID			 NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    APPROVAL_DASHBOARD_SID    NUMBER(10, 0)    NOT NULL,
    IND_SID                   NUMBER(10, 0)    NOT NULL,
	HIDDEN_DTM				  DATE,
	ALLOW_ESTIMATED_DATA 	  NUMBER(1) 	   DEFAULT 0 NOT NULL,
	POS 					  NUMBER(10) 	   DEFAULT 0 NOT NULL,
    CONSTRAINT PK_APPROVAL_DASHBOARD_IND PRIMARY KEY (CSRIMP_SESSION_ID, APPROVAL_DASHBOARD_SID, IND_SID),
	CONSTRAINT FK_APPROVAL_DASHBOARD_IND_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.BATCH_JOB_APPROVAL_DASH_VALS (
    CSRIMP_SESSION_ID			 NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DASHBOARD_INSTANCE_ID        NUMBER(10, 0)     NOT NULL,
    BATCH_JOB_ID                 NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_BATCH_JOB_APPR_DASH_VALS PRIMARY KEY (CSRIMP_SESSION_ID, DASHBOARD_INSTANCE_ID, BATCH_JOB_ID),
	CONSTRAINT FK_BATCH_JOB_APPR_DASH_VALS_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.APPROVAL_NOTE_PORTLET_NOTE (
  CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
  VERSION                   NUMBER(10, 0)     NOT NULL,
  TAB_PORTLET_ID            NUMBER(10, 0)     NOT NULL,
  APPROVAL_DASHBOARD_SID    NUMBER(10, 0)     NOT NULL,
  DASHBOARD_INSTANCE_ID     NUMBER(10, 0)     NOT NULL,
  REGION_SID                NUMBER(10, 0)     NOT NULL,
  NOTE                      VARCHAR2(1024),
  ADDED_DTM                 DATE,
  ADDED_BY_SID              NUMBER(10, 0)     NOT NULL,
  CONSTRAINT PK_APPR_NOTE_PORTLET_NOTE PRIMARY KEY (CSRIMP_SESSION_ID, VERSION, TAB_PORTLET_ID, APPROVAL_DASHBOARD_SID, DASHBOARD_INSTANCE_ID, REGION_SID),
  CONSTRAINT FK_APPR_NOTE_PORTLET_NOTE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.TPL_REPORT_TAG_APPROVAL_NOTE (
  CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
  TPL_REPORT_TAG_APP_NOTE_ID  NUMBER(10)        NOT NULL,
  TAB_PORTLET_ID              NUMBER(10, 0)     NOT NULL,
  APPROVAL_DASHBOARD_SID      NUMBER(10, 0)     NOT NULL,
  CONSTRAINT PK_TPL_REPORT_TAG_APP_NOTE PRIMARY KEY (CSRIMP_SESSION_ID, TPL_REPORT_TAG_APP_NOTE_ID),
  CONSTRAINT FK_TPL_REPORT_TAG_APP_NOTE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


CREATE TABLE CSRIMP.TPL_REPORT_TAG_APPROVAL_MATRIX (
  CSRIMP_SESSION_ID				NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
  TPL_REPORT_TAG_APP_MATRIX_ID	NUMBER(10)			NOT NULL,
  APPROVAL_DASHBOARD_SID		NUMBER(10, 0)		NOT NULL,
  CONSTRAINT PK_TPL_REP_TAG_APP_MATRIX PRIMARY KEY (CSRIMP_SESSION_ID, TPL_REPORT_TAG_APP_MATRIX_ID),
  CONSTRAINT FK_TPL_REP_TAG_APP_MATRIX_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- TODO: 
-- CSRIMP.AGGREGATE_IND_VAL_DETAIL
-- CSRIMP.APPROVAL_DASHBOARD_VAL_SRC

-- Alter tables
ALTER TABLE CSRIMP.APPROVAL_DASHBOARD_INSTANCE ADD (
	LAST_REFRESHED_DTM				DATE,
	IS_LOCKED						NUMBER(1, 0)	NOT NULL,
	IS_SIGNED_OFF					NUMBER(1)		NOT NULL
);

ALTER TABLE CSRIMP.TPL_REPORT_TAG_DATAVIEW ADD (
	APPROVAL_DASHBOARD_SID			NUMBER(10),
	IND_TAG 							NUMBER(10)
);

ALTER TABLE CSRIMP.TPL_REPORT_TAG  ADD (
	TPL_REPORT_TAG_APP_NOTE_ID 		NUMBER(10, 0),
	TPL_REPORT_TAG_APP_MATRIX_ID 	NUMBER(10, 0)
);

ALTER TABLE CSRIMP.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;
ALTER TABLE CSRIMP.TPL_REPORT_TAG ADD(
	CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL))
);

ALTER TABLE CSRIMP.APPROVAL_DASHBOARD ADD (
	START_DTM                    	DATE NOT NULL,
	END_DTM                     	DATE NOT NULL,
	ACTIVE_PERIOD_SCENARIO_RUN_SID	NUMBER(10, 0),
	SIGNED_OFF_SCENARIO_RUN_SID 	NUMBER(10, 0),
	INSTANCE_CREATION_SCHEDULE 		XMLTYPE,
	PERIOD_SET_ID 					NUMBER(10) NOT NULL,
	PERIOD_INTERVAL_ID				NUMBER(10) NOT NULL,
	PUBLISH_DOC_FOLDER_SID 			NUMBER(10, 0)
);

-- some oldie that needed fix
ALTER TABLE CSRIMP.DELEGATION_DESCRIPTION DROP CONSTRAINT PK_DELEGATION_DESCRIPTION;
ALTER TABLE CSRIMP.DELEGATION_DESCRIPTION ADD CONSTRAINT PK_DELEGATION_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, DELEGATION_SID, LANG);
 
ALTER TABLE CSRIMP.DELEG_PLAN_DATE_SCHEDULE DROP CONSTRAINT UK_DELEG_PLAN_DATE_SCHEDULE;
ALTER TABLE CSRIMP.DELEG_PLAN_DATE_SCHEDULE ADD CONSTRAINT UK_DELEG_PLAN_DATE_SCHEDULE UNIQUE (CSRIMP_SESSION_ID, DELEG_PLAN_SID, ROLE_SID, DELEG_PLAN_COL_ID);

-- *** Grants ***

grant select,insert,update,delete on csrimp.tpl_report_tag_approval_note to web_user;
grant insert on csr.tpl_report_tag_approval_note to csrimp;
grant select on csr.tpl_report_tag_app_note_id_seq to csrimp;

grant select,insert,update,delete on csrimp.tpl_report_tag_approval_matrix to web_user;
grant insert on csr.tpl_report_tag_approval_matrix to csrimp;
grant select on csr.tpl_rep_tag_app_matrix_id_seq to csrimp;

grant select,insert,update,delete on csrimp.approval_dashboard_val to web_user;
grant insert on csr.approval_dashboard_val to csrimp;
grant select on csr.approval_dashboard_val_id_seq to csrimp;

grant select,insert,update,delete on csrimp.batch_job_approval_dash_vals to web_user;
grant insert on csr.batch_job_approval_dash_vals to csrimp;

grant select,insert,update,delete on csrimp.approval_note_portlet_note to web_user;
grant insert on csr.approval_note_portlet_note to csrimp;

grant select,insert,update,delete on csrimp.approval_dashboard_ind to web_user;
grant insert on csr.approval_dashboard_ind to csrimp;

-- oldies needed fixing
grant select,insert,update,delete on csrimp.chain_saved_filter_alert to web_user;
grant select,insert,update,delete on csrimp.chain_saved_fltr_alrt_sbscrptn to web_user;

grant select, insert, update on chain.saved_filter_alert to csrimp;
grant select, insert, update on chain.saved_filter_alert_subscriptn to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('MAP_TPL_REP_TAG_APPR_NOTE', 'MAP_TPL_REPORT_TAG_APPR_MATR', 'MAP_APPR_DASH_VAL', 'MAP_APPR_DASH_VAL_SRC',
								'APPROVAL_DASHBOARD_VAL', 'APPROVAL_DASHBOARD_IND', 'BATCH_JOB_APPROVAL_DASH_VALS', 'APPROVAL_NOTE_PORTLET_NOTE', 
								'TPL_REPORT_TAG_APPROVAL_NOTE', 'TPL_REPORT_TAG_APPROVAL_MATRIX')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/
-- Data

-- ** New package grants **

-- *** Packages ***
@../schema_pkg
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail


