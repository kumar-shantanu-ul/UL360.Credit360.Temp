-- Please update version.sql too -- this keeps clean builds in sync
define version=3430
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.REGION_ENERGY_RATING_ID_SEQ;

-- Alter tables
ALTER TABLE csr.region_energy_rating DROP CONSTRAINT PK_REGION_ENERGY_RAT;

ALTER TABLE csr.region_energy_rating ADD (
	REGION_ENERGY_RATING_ID			NUMBER(10, 0) NULL,
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);

UPDATE csr.region_energy_rating SET region_energy_rating_id = CSR.REGION_ENERGY_RATING_ID_SEQ.NEXTVAL;

ALTER TABLE csr.region_energy_rating MODIFY	REGION_ENERGY_RATING_ID	NUMBER(10, 0) NOT NULL;

ALTER TABLE csr.region_energy_rating ADD CONSTRAINT PK_REGION_ENERGY_RAT PRIMARY KEY (app_sid, region_energy_rating_id);

ALTER TABLE csrimp.region_energy_rating ADD (
	REGION_ENERGY_RATING_ID			NUMBER(10, 0) NULL,
	NOTE							VARCHAR2(2048) NULL,
	SUBMIT_TO_GRESB					NUMBER(1) DEFAULT 0 NOT NULL
);

CREATE INDEX CSR.IX_REGION_ENERGY_REGION_SID ON CSR.REGION_ENERGY_RATING (APP_SID, REGION_SID);

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

@update_tail
