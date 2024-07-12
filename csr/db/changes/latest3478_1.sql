-- Please update version.sql too -- this keeps clean builds in sync
define version=3478
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
v_anonymise_capability				NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_anonymise_capability
	  FROM csr.capability
	 WHERE name = 'Anonymise PII data';
	
	IF v_anonymise_capability = 0 THEN
		INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Anonymise PII data', 1, 'When enabled, this capability will be granted to the Admin group. Subsequently, please run the existing utilscript to grant this capability to Superadmins instead.');
	ELSE
		UPDATE csr.capability 
		   SET description = 'When enabled, this capability will be granted to the Admin group. Subsequently, please run the existing utilscript to grant this capability to Superadmins instead.'
		 WHERE name = 'Anonymise PII data';
	END IF;

END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
