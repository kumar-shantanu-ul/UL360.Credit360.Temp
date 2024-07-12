-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
    COLUMN_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT (COLUMN_EXISTS, -01430);
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.CUSTOMER ADD (ENABLE_JAVA_AUTH NUMBER(1) DEFAULT 0 NOT NULL, CONSTRAINT CK_ENABLE_JAVA_AUTH CHECK (ENABLE_JAVA_AUTH IN (0, 1)))';
EXCEPTION
	WHEN COLUMN_EXISTS THEN NULL;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (69, 'Disable new password hashing scheme', 'Switches the users directly belonging to this site back to legacy password authenticaton.', 'DisableJavaAuth', NULL);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (70, 'Enable new password hashing scheme', 'Switches the users directly belonging to this site to the new password authentication module.', 'EnableJavaAuth', NULL);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body
@../csr_user_body

@update_tail
