-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=23
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
BEGIN
  INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('View initiatives audit log', 0);
EXCEPTION 
  WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
-- ** New package grants **

-- *** Packages ***
@..\initiative_body

@update_tail
