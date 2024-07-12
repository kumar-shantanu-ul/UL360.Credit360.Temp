-- Please update version.sql too -- this keeps clean builds in sync
define version=3353
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.CONTEXT_SENSITIVE_HELP_REDIRECT (
	source_path			VARCHAR(2048)	NOT NULL,
	help_path			VARCHAR(2048)	NOT NULL,
	CONSTRAINT PK_CONTEXT_SENSITIVE_HELP_REDIRECT PRIMARY KEY (source_path)
);

CREATE TABLE CSR.CONTEXT_SENSITIVE_HELP_BASE (
	client_help_root	VARCHAR(128) NOT NULL,
	internal_help_root	VARCHAR(128) NOT NULL,
	CONSTRAINT PK_CONTEXT_SENSITIVE_HELP_BASE PRIMARY KEY (client_help_root, internal_help_root)
);
-- Restrict to one row
CREATE UNIQUE INDEX CONTEXT_SENSITIVE_HELP_BASE_UK ON CSR.CONTEXT_SENSITIVE_HELP_BASE ('1');

-- Alter tables

-- *** Grants ***
CREATE OR REPLACE PACKAGE csr.context_sensitive_help_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.context_sensitive_help_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/

GRANT EXECUTE ON csr.context_sensitive_help_pkg TO web_user;


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Context Sensitive Help', 0, 'Enable context sensitive help for this site.');
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Context Sensitive Help Management', 0, 'Enable context sensitive help global management page.');

	INSERT INTO CSR.CONTEXT_SENSITIVE_HELP_BASE (client_help_root, internal_help_root) VALUES ('http://cr360.helpdocsonline.com/', 'http://emu.helpdocsonline.com/');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../unit_test_body

@../context_sensitive_help_pkg
@../context_sensitive_help_body

@update_tail
