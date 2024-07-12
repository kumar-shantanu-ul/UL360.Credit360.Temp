-- Please update version.sql too -- this keeps clean builds in sync
define version=3383
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT FK_REG_CERT_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

ALTER TABLE CSR.REGION_ENERGY_RATINGS ADD CONSTRAINT FK_REG_ENE_RAT_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

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

@update_tail
