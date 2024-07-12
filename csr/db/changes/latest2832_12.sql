-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX chain.ix_cap_flow_cap_capability ON chain.capability_flow_capability (capability_id);
CREATE INDEX chain.ix_cap_flow_cap_flow_cap ON chain.capability_flow_capability (app_sid, flow_capability_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
