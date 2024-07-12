-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=7
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

UPDATE csr.module SET enable_class = null, post_enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableQuestionLibrary';
UPDATE csr.module SET enable_class = null, post_enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableFileSharingApi';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
