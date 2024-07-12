-- Please update version.sql too -- this keeps clean builds in sync
define version=3436
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.region_certificate ADD (
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csr.region_certificate DROP CONSTRAINT uk_reg_cert_ext_id;

ALTER TABLE csrimp.region_certificate ADD (
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.region_certificate DROP CONSTRAINT uk_reg_cert_ext_id;

CREATE INDEX csr.ix_region_certif_region_sid ON csr.region_certificate (app_sid, region_sid);

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
@../region_certificate_body
@../schema_body
@../csrimp/imp_body

@update_tail
