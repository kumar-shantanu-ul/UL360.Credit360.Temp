-- Please update version.sql too -- this keeps clean builds in sync
define version=3472
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CMS.CK_CONS MODIFY CONSTRAINT_NAME VARCHAR2(128);
ALTER TABLE CMS.FK_CONS MODIFY CONSTRAINT_NAME VARCHAR2(128);
ALTER TABLE CMS.UK_CONS MODIFY CONSTRAINT_NAME VARCHAR2(128);

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

@update_tail
