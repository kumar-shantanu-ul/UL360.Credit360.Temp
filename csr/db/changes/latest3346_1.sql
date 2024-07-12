-- Please update version.sql too -- this keeps clean builds in sync
define version=3346
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.MANAGED_CONTENT_MEASURE_CONVERSION_MAP(
	APP_SID 				NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL, 
	CONVERSION_ID			NUMBER(10,0) NOT NULL, 
	UNIQUE_REF 				VARCHAR2(1024) NOT NULL, 
	PACKAGE_REF 			VARCHAR2(1024) NOT NULL, 
	CONSTRAINT PK_MANAGED_CONTENT_MC_MAP PRIMARY KEY (APP_SID, CONVERSION_ID, UNIQUE_REF)
);

-- Alter tables

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
@../measure_body
@../indicator_api_pkg
@../indicator_api_body
@../managed_content_pkg
@../managed_content_body

@update_tail
