-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=34
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.comp_permit_sched_issue (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	issue_scheduled_task_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_comp_pmt_reg_sched_issue PRIMARY KEY (app_sid, flow_item_id, issue_scheduled_task_id),	
	CONSTRAINT fk_cmp_pmt_schd_iss_flow_item FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.flow_item (app_sid, flow_item_id),
	CONSTRAINT fk_cmp_pmt_schd_iss_iss_sched FOREIGN KEY (app_sid, issue_scheduled_task_id)
		REFERENCES csr.issue_scheduled_task (app_sid, issue_scheduled_task_id)
);

create index csr.ix_comp_permit_s_issue_schedul on csr.comp_permit_sched_issue (app_sid, issue_scheduled_task_id);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.schema_table (MODULE_NAME, OWNER, TABLE_NAME)
VALUES ('Permits', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');

INSERT INTO csr.schema_column (COLUMN_NAME, IS_MAP_SOURCE, MAP_NEW_ID_COL, MAP_OLD_ID_COL, MAP_TABLE, OWNER, TABLE_NAME)
VALUES('FLOW_ITEM_ID', 0, 'NEW_FLOW_ITEM_ID', 'OLD_FLOW_ITEM_ID', 'MAP_FLOW_ITEM', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');

INSERT INTO csr.schema_column (COLUMN_NAME, IS_MAP_SOURCE, MAP_NEW_ID_COL, MAP_OLD_ID_COL, MAP_TABLE, OWNER, TABLE_NAME)
VALUES('ISSUE_SCHEDULED_TASK_ID', 0, 'NEW_ISSUE_SCHEDULED_TASK_ID', 'OLD_ISSUE_SCHEDULED_TASK_ID', 'MAP_ISSUE_SCHEDULED_TASK', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');

INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (35, 'permit', 'Updated');

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit scheduled actions tab', '/csr/site/compliance/controls/PermitScheduledActionsTab.js', 'Credit360.Compliance.Controls.PermitScheduledActionsTab', 'Credit360.Compliance.Plugins.PermitScheduledActionsTab', 'Shows permit scheduled actions.');

UPDATE csr.issue_type 
   SET helper_pkg = 'csr.permit_pkg' 
 WHERE issue_type_id = 22;
 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
 
@../csr_data_pkg 
@../permit_pkg  

@../compliance_setup_body
@../enable_body 
@../permit_body  
@../compliance_body  
@../csr_app_body 
@../csrimp/imp_body

@update_tail
