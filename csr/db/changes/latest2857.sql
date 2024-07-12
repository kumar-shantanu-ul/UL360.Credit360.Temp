-- Please update version.sql too -- this keeps clean builds in sync
define version=2857
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

UPDATE CSR.MODULE
SET DESCRIPTION='Enables campaigns (does not enable recipients lists or the Recipients page, which must be set up separately by a developer)'
WHERE MODULE_ID = 55
AND MODULE_NAME = 'Campaigns';
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***



@update_tail
