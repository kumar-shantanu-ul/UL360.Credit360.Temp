-- Please update version.sql too -- this keeps clean builds in sync
define version=3498
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_check
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'ALERT'
	   AND constraint_name = 'FK_ALERT_CSR_USER';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ALERT ADD CONSTRAINT FK_ALERT_CSR_USER FOREIGN KEY (APP_SID, TO_USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID)';
	END IF;
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
@../issue_pkg
@../issue_body

@update_tail
