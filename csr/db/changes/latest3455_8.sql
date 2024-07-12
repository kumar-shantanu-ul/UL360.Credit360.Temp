-- Please update version.sql too -- this keeps clean builds in sync
define version=3455
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
UPDATE ASPEN2.APPLICATION SET BRANDING_SERVICE_ENABLED = 1 WHERE BRANDING_SERVICE_ENABLED = 2;
ALTER TABLE ASPEN2.APPLICATION DROP COLUMN BRANDING_SERVICE_CSS;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION DROP COLUMN BRANDING_SERVICE_CSS:

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../branding_pkg
@../../../aspen2/db/aspenapp_body
@../branding_body
@../schema_body
@../site_name_management_body
@../csrimp/imp_body

@update_tail
