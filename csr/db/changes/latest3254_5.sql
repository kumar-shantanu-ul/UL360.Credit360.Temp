-- Please update version.sql too -- this keeps clean builds in sync
define version=3254
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE aspen2.application ADD branding_service_css VARCHAR2(512);
ALTER TABLE csrimp.aspen2_application ADD branding_service_css VARCHAR2(512);

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
@../csrimp/imp_body
@../../../aspen2/db/aspenapp_body
@../schema_body

@update_tail
