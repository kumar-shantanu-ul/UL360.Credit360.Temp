-- Please update version.sql too -- this keeps clean builds in sync
define version=3179
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	does_not_exist EXCEPTION;
	PRAGMA EXCEPTION_INIT(does_not_exist, -4043);
BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE CSR.T_COMPLIANCE_RLLVL_RT_TABLE';
	EXCEPTION WHEN does_not_exist THEN
		NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE CSR.T_COMPLIANCE_ROLLOUTLVL_RT';
	EXCEPTION WHEN does_not_exist THEN
		NULL;
	END;
END;
/

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
@../compliance_pkg
@../compliance_body

@update_tail
