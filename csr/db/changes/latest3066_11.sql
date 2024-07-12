-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=11
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
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (31, 'condition', 'Updated');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_data_pkg
@..\compliance_pkg

@..\compliance_body
@..\compliance_setup_body

@update_tail
