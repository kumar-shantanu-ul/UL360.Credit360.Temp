-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=2
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
INSERT INTO csr.capability (name, allow_by_default) VALUES ('View user details', 0);

-- ** New package grants **

-- *** Packages ***
@../csr_user_body

@update_tail
