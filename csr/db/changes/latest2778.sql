-- Please update version.sql too -- this keeps clean builds in sync
define version=2778
define minor_version=0
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
UPDATE csr.capability
   SET allow_by_default = 1
 WHERE name = 'View initiatives audit log';
 
-- ** New package grants **

-- *** Packages ***

@update_tail
