-- Please update version.sql too -- this keeps clean builds in sync
define version=3382
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.REGION_ENERGY_RATINGS DROP COLUMN CERTIFICATE_NUMBER;
ALTER TABLE CSRIMP.REGION_ENERGY_RATINGS DROP COLUMN CERTIFICATE_NUMBER;

ALTER TABLE CSR.REGION_CERTIFICATES DROP CONSTRAINT PK_REGION_CERTS;
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT PK_REGION_CERTS PRIMARY KEY (APP_SID, REGION_SID, CERTIFICATION_ID, ISSUED_DTM, EXPIRY_DTM);

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
@../region_certificate_pkg

@../csrimp/imp_body
@../region_certificate_body
@../schema_body

@update_tail
