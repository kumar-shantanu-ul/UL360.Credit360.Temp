-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=34
@update_header

-- *** DDL ***
-- Create tables
DECLARE
	v_curr_val  NUMBER(10);
BEGIN
	SELECT csr.comp_item_region_log_id_seq.nextval INTO v_curr_val FROM dual;
	EXECUTE IMMEDIATE(
		'CREATE SEQUENCE csr.flow_item_audit_log_id_seq START WITH ' || v_curr_val
	);
END;
/

DROP SEQUENCE csr.comp_item_region_log_id_seq;

-- Alter tables
ALTER TABLE csr.compliance_item_region_log
	RENAME COLUMN compliance_item_region_log_id TO flow_item_audit_log_id;
	
ALTER TABLE csr.compliance_item_region_log
	RENAME TO flow_item_audit_log;
	
ALTER TABLE csr.flow_item_audit_log ADD (
	PARAM_1			VARCHAR2(255),
	PARAM_2			VARCHAR2(255),
	PARAM_3			VARCHAR2(255)
);

ALTER INDEX csr.pk_compliance_item_region_log RENAME TO pk_flow_item_audit_log;
ALTER INDEX csr.ix_compliance_it_user_sid RENAME TO ix_flow_it_aud_log_user_sid;
ALTER INDEX csr.ix_compliance_it_flow_item_id RENAME TO ix_flow_it_aud_log_flow_it_id;

ALTER TABLE csrimp.compliance_item_region_log
	RENAME COLUMN compliance_item_region_log_id TO flow_item_audit_log_id;
	
ALTER TABLE csrimp.compliance_item_region_log
	RENAME TO flow_item_audit_log;
	
ALTER TABLE csrimp.flow_item_audit_log ADD (
	PARAM_1			VARCHAR2(255),
	PARAM_2			VARCHAR2(255),
	PARAM_3			VARCHAR2(255)
);

ALTER TABLE csrimp.map_compliance_item_region_log
	RENAME COLUMN old_comp_item_region_log_id TO old_flow_item_audit_log_id;
	
ALTER TABLE csrimp.map_compliance_item_region_log
	RENAME COLUMN new_comp_item_region_log_id TO new_flow_item_audit_log_id;

ALTER TABLE csrimp.map_compliance_item_region_log
	RENAME TO map_flow_item_audit_log;

ALTER TABLE csr.temp_compliance_log_ids
	RENAME COLUMN compliance_item_region_log_id TO flow_item_audit_log_id;
	
ALTER TABLE csr.temp_compliance_log_ids
	RENAME TO temp_flow_item_audit_log;

ALTER TABLE csr.flow_item_audit_log DROP CONSTRAINT FK_CMP_ITM_REG_LOG_CMP_ITM_REG;

-- *** Grants ***
GRANT SELECT ON csr.flow_item_audit_log_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.flow_item_audit_log TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit audit log tab', '/csr/site/compliance/controls/FlowItemAuditLogTab.js', 'Credit360.Compliance.Controls.FlowItemAuditLogTab', 'Credit360.Compliance.Plugins.FlowItemAuditLogTab', 'Shows the audit history of a permit item.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg
@../schema_pkg

@../permit_body
@../compliance_body
@../csr_app_body
@../schema_body
@../csrimp/imp_body

@update_tail
