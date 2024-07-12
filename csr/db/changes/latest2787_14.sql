-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=14
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

/* 
Remove obsolete 'Check conditional indicators on delegation import' capability from:
abinbev.credit360.com
centrica-epr-test.credit360.com
centrica.credit360.com
sabmiller.credit360.com
cewe.credit360.com
aegon.credit360.com
sabmillersam.credit360.com
*/
DELETE FROM security.securable_object 
 WHERE class_id = (SELECT class_id FROM security.securable_object_class WHERE class_name = 'CSRCapability') AND
       name = 'Check conditional indicators on delegation import';

DELETE FROM csr.capability 
 WHERE NAME='Check conditional indicators on delegation import';

-- ** New package grants **

-- *** Packages ***

@update_tail
