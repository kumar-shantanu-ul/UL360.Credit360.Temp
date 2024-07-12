-- Please update version.sql too -- this keeps clean builds in sync
define version=3003
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.sheet_val_change_log
 DROP CONSTRAINT ck_sheet_val_change_log_dates;

ALTER TABLE csr.sheet_val_change_log
  ADD CONSTRAINT ck_sheet_val_change_log_dates CHECK (start_dtm = TRUNC(start_dtm, 'DD') AND end_dtm = TRUNC(end_dtm, 'DD') AND end_dtm > start_dtm);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
