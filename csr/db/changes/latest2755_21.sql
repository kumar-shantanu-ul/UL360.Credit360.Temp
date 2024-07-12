-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=21
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

-- ** New package grants **
create or replace package csr.initiative_export_pkg as end;
/
grant execute on csr.initiative_export_pkg to web_user;

-- *** Packages ***
@..\initiative_import_pkg
@..\initiative_export_pkg
@..\initiative_import_body
@..\initiative_export_body

@update_tail
