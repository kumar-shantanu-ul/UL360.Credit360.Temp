-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index csr.ix_flow_inv_type_flow_alert_cl on csr.flow_inv_type_alert_class (app_sid, flow_alert_class);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
