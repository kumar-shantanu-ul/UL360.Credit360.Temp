-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=8
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

INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (33, 'condition', 'Compliant');

INSERT INTO csr.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
VALUES (1065, 'Non-Compliant Permit Conditions', 'Credit360.Portlets.Compliance.NonCompliantConditions', '/csr/site/portal/portlets/compliance/NonCompliantConditions.js');

-- push the new nature to existing states
UPDATE csr.flow_state set flow_state_nature_id = 33 where flow_state_id in (
	
SELECT fs.flow_state_id
  FROM csr.flow_state fs
  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND FS.lookup_key = 'COMPLIANT'
  JOIN csr.compliance_options co ON co.condition_flow_sid = f.flow_sid)
  


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_data_pkg
@../compliance_pkg

@../compliance_setup_body
@../compliance_body
@../enable_body


@update_tail
