-- Please update version.sql too -- this keeps clean builds in sync
define version=2802
define minor_version=0
define is_combined=0
@update_header

-- *** DDL ***
-- Create tables
ALTER TABLE csrimp.flow_state_transition_role MODIFY role_sid NULL;
ALTER TABLE csrimp.flow_transition_alert_role MODIFY role_sid NULL;
ALTER TABLE csrimp.flow_state_role MODIFY role_sid NULL;

-- *** Packages ***
@../csrimp/imp_body

@update_tail
