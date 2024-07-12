-- Please update version.sql too -- this keeps clean builds in sync
define version=3344
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.module ADD (
	post_enable_class	VARCHAR2(1024)
);

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
@../enable_body

@update_tail
