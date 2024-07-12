-- Please update version.sql too -- this keeps clean builds in sync
define version=3263
define minor_version=3
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

-- fix broken data (all 7 cases on live db are 1 year out due to importing with the wrong year)
UPDATE csr.period_dates
   SET end_dtm = ADD_MONTHS(end_dtm, 12)
 WHERE start_dtm > end_dtm;


-- now add constraint on period date
ALTER TABLE csr.period_dates ADD CONSTRAINT CK_PERIOD_DATES_SPAN CHECK (start_dtm < end_dtm);

ALTER TABLE csrimp.period_dates ADD CONSTRAINT CK_PERIOD_DATES_SPAN CHECK (start_dtm < end_dtm);



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
