-- Please update version.sql too -- this keeps clean builds in sync
define version=2858
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index csr.ix_meter_aggrega_meter_input_i on csr.meter_aggregate_type (app_sid, meter_input_id, aggregator);

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
