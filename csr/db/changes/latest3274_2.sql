-- Please update version.sql too -- this keeps clean builds in sync
define version=3274
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD USE_BETA_MENU NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_USE_BETA_MENU CHECK (USE_BETA_MENU IN (0,1));

--csrimp
ALTER TABLE CSRIMP.CUSTOMER ADD USE_BETA_MENU NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER MODIFY (USE_BETA_MENU DEFAULT NULL);
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_USE_BETA_MENU CHECK (USE_BETA_MENU IN (0,1));

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
@../customer_body
@../schema_body

@../csrimp/imp_body

@update_tail
