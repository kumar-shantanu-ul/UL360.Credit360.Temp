-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE ASPEN2.APPLICATION ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE ASPEN2.APPLICATION ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));

UPDATE aspen2.application a
   SET ul_design_system_enabled = (
		SELECT ul_design_system_enabled
		  FROM csr.customer c
		 WHERE a.app_sid = c.app_sid
	);

ALTER TABLE CSR.CUSTOMER DROP COLUMN UL_DESIGN_SYSTEM_ENABLED;
ALTER TABLE CSRIMP.CUSTOMER DROP COLUMN UL_DESIGN_SYSTEM_ENABLED;

ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION MODIFY (UL_DESIGN_SYSTEM_ENABLED DEFAULT NULL);
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));

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
@../branding_body
@../csrimp/imp_body
@../customer_body
@../schema_body

@update_tail
