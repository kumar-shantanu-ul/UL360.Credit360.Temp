-- Please update version.sql too -- this keeps clean builds in sync
define version=3396
define minor_version=6
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
-- Previous script should have failed but decided to delete record in case someone performed the insert by using the plural form for flow_alert_class thinking it was a spelling mistake
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
