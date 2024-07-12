-- Please update version.sql too -- this keeps clean builds in sync
define version=2799
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csrimp.flow_state_transition_role ADD group_sid NUMBER(10);
ALTER TABLE csrimp.flow_transition_alert_role ADD group_sid NUMBER(10);
ALTER TABLE csrimp.flow_state_role ADD group_sid NUMBER(10);
ALTER TABLE csrimp.flow_state_role_capability ADD group_sid NUMBER(10);

CREATE INDEX csr.ix_flow_item_gen_proc_dtm_fi ON csr.flow_item_generated_alert (app_sid, processed_dtm, flow_item_id);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/tab_body
@../flow_body
@../schema_body
@../csrimp/imp_body

@update_tail
