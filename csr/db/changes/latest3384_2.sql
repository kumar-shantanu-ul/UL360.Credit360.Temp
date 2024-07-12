-- Please update version.sql too -- this keeps clean builds in sync
define version=3384
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.region_certificates
ADD external_certificate_id VARCHAR2(255);

ALTER TABLE csrimp.region_certificates
ADD external_certificate_id VARCHAR2(255);

ALTER TABLE csr.region_certificates
ADD CONSTRAINT UK_REG_CERT_EXT_ID UNIQUE (app_sid, region_sid, certification_id, certification_level_id, external_certificate_id);

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
@../property_pkg
@../region_certificate_pkg
@../region_certificate_body
@../schema_body
@../csrimp/imp_body

@update_tail
