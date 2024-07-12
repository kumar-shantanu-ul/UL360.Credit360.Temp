-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.enhesa_account(
	only_one_row NUMBER(1) DEFAULT 0 NOT NULL,
	username VARCHAR2(1024) NOT NULL,
	password VARCHAR2(1024) NOT NULL,
	CONSTRAINT CK_ENHESA_ACCOUNT_ONE_ROW CHECK (only_one_row = 0),
    CONSTRAINT PK_ENHESA_ACCOUNT PRIMARY KEY (only_one_row)
);

-- Move any existing account details.
INSERT INTO csr.enhesa_account (username, password)
SELECT username, password
  FROM csr.enhesa_options
 WHERE rownum = 1;

-- Alter tables
ALTER TABLE csr.enhesa_options
DROP (username, password);

ALTER TABLE csrimp.enhesa_options
DROP (username, password);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS
DELETE FROM csr.module_param WHERE module_id = '80' AND param_name = 'in_username';

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\compliance_pkg
@@..\csrimp\imp_pkg
@@..\enable_pkg

@@..\compliance_body
@@..\csrimp\imp_body
@@..\schema_body
@@..\enable_body


@update_tail
