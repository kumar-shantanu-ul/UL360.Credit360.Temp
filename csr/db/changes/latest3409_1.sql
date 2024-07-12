-- Please update version.sql too -- this keeps clean builds in sync
define version=3409
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE ASPEN2.APPLICATION ADD BRANDING_SERVICE_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE ASPEN2.APPLICATION ADD CONSTRAINT CK_BRANDING_SERVICE_ENABLED CHECK (BRANDING_SERVICE_ENABLED IN (0,1,2));

ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD BRANDING_SERVICE_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD CONSTRAINT CK_BRANDING_SERVICE_ENABLED CHECK (BRANDING_SERVICE_ENABLED IN (0,1,2));

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
@../../../aspen2/db/aspenapp_body
@../branding_pkg
@../branding_body
@../schema_body
@../csrimp/imp_body

@update_tail
