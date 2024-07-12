-- Please update version.sql too -- this keeps clean builds in sync
define version=3398
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));

ALTER TABLE CSRIMP.CUSTOMER ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (UL_DESIGN_SYSTEM_ENABLED DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));

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
@../customer_body
@../schema_body

@update_tail
