-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=18
@update_header
-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.route ADD completed_dtm DATE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../delegation_pkg
@../delegation_body
@../section_body

@update_tail