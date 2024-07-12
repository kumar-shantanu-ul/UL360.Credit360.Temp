-- Please update version.sql too -- this keeps clean builds in sync
define version=2799
define minor_version=9
@update_header

-- UNDO
--alter table csr.customer drop column legacy_period_formatting;

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.customer add legacy_period_formatting number(1,0) default 0;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- All existing customers (except aspen pharma) use legacy formatting
update csr.customer 
   set legacy_period_formatting = 1 
 where app_sid <> 29144945;

update csr.period_interval
   set single_interval_label = '{1:YYYY}'
 where app_sid = 29144945
   and period_set_id = 1
   and period_interval_id = 4;

-- ** New package grants **

-- *** Packages ***
@../csr_app_body

@update_tail
