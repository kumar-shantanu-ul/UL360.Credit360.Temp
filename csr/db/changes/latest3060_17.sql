-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_options ADD (
	condition_flow_sid	NUMBER(10,0) NULL
);

ALTER TABLE csrimp.compliance_options ADD (
	condition_flow_sid	NUMBER(10,0) NULL
);

ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_co_con_flow 
	FOREIGN KEY (app_sid, condition_flow_sid) 
	REFERENCES csr.flow (app_sid, flow_sid);

CREATE INDEX csr.ix_compliance_op_condition_f ON csr.compliance_options (app_sid, condition_flow_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('condition', 'Condition', 'csr.permit_pkg');

INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (26, 'condition', 'Not created');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (27, 'condition', 'Active');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (28, 'condition', 'Inactive');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_setup_pkg
@../compliance_pkg
@../permit_pkg

@../compliance_setup_body
@../compliance_body
@../permit_body

@../schema_body
@../enable_body
@../csrimp/imp_body

@update_tail
