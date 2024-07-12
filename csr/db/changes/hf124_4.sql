-- Please update version.sql too -- this keeps clean builds in sync
--define version=xxxx
--define minor_version=x
--@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.val_change
MODIFY val_change_id number(12);

ALTER TABLE csrimp.val_change
MODIFY val_change_id number(12);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

--@update_tail
