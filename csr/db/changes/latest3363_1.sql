-- Please update version.sql too -- this keeps clean builds in sync
define version=3363
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg)
VALUES ('disclosure', 'Disclosure', 'csr.disclosure_flow_helper_pkg');

INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg)
VALUES ('disclosuredelegation', 'Disclosure Delegation', 'csr.disclosure_flow_helper_pkg');

INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
VALUES (38, 'disclosuredelegation', 'Promoted to Approved');

INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
VALUES (39, 'disclosure', 'Promoted to Submission');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
