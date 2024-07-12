-- Please update version.sql too -- this keeps clean builds in sync
define version=2821
define minor_version=6
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

DELETE FROM csr.branding_availability
 WHERE client_folder_name in ('dbdms', 't-mobile');

DELETE FROM csr.branding
 WHERE client_folder_name in ('dbdms', 't-mobile');

-- ** New package grants **

-- *** Packages ***

@update_tail
