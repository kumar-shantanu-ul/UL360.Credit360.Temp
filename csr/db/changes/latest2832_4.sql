-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS
-- Data

-- Switch legacy formatting back off for Aspen Pharma
update csr.customer 
   set legacy_period_formatting = 0 
 where app_sid = 29144945;

-- And fix the default period set to match their reporting period
update csr.period 
   set start_dtm = add_months(start_dtm, 12), 
	   end_dtm = add_months(end_dtm, 12)
 where period_set_id = 1 
   and period_id < 7
   and app_sid = 29144945;

-- ** New package grants **

-- *** Packages ***
@../period_body

@update_tail
