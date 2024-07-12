-- Please update version.sql too -- this keeps clean builds in sync
define version=3342
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD MOBILE_BRANDING_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_ENABLE_MOBILE_BRANDING CHECK (MOBILE_BRANDING_ENABLED IN (0,1));

ALTER TABLE CSRIMP.CUSTOMER ADD MOBILE_BRANDING_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (MOBILE_BRANDING_ENABLED DEFAULT NULL);

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
@../branding_body
@../csrimp/imp_body

@update_tail
