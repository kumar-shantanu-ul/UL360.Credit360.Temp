-- Please update version.sql too -- this keeps clean builds in sync
define version=3034
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('regulation', 'Regulation', 'CSR.COMPLIANCE_PKG');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (5, 'regulation', 'New');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (6, 'regulation', 'Updated');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (7, 'regulation', 'Action Required');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (8, 'regulation', 'Compliant');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (9, 'regulation', 'Not applicable');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (10, 'regulation', 'Retired');

INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('requirement', 'Requirement', 'CSR.COMPLIANCE_PKG');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (11, 'requirement', 'New');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (12, 'requirement', 'Updated');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (13, 'requirement', 'Action Required');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (14, 'requirement', 'Compliant');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (15, 'requirement', 'Not applicable');
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (16, 'requirement', 'Retired');

INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (79, 'in_enable_regulation_flow', 0, 'Should the regulation workflow be created? (Y/N)');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (79, 'in_enable_requirement_flow', 1, 'Should the requirement workflow be created? (Y/N)');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../compliance_pkg

@../compliance_body
@../enable_body

@update_tail
