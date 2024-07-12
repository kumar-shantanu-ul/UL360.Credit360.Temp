-- Please update version.sql too -- this keeps clean builds in sync
define version=3425
define minor_version=8
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
-- Note, not present in basedata.sql as it's intended to be removed soon after verification.
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('HAProxyTest', 0, 'Use the test HAProxy IP address (internal use only).');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
