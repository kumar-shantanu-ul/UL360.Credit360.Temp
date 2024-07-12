-- Please update version.sql too -- this keeps clean builds in sync
define version=3323
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.auto_impexp_instance_msg
ADD message_clob CLOB NULL;

BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE csr.auto_impexp_instance_msg
	   SET message_clob = message;
END;
/

ALTER TABLE csr.auto_impexp_instance_msg
DROP COLUMN message;

ALTER TABLE csr.auto_impexp_instance_msg
RENAME COLUMN message_clob TO message;

ALTER TABLE csr.auto_impexp_instance_msg
MODIFY message NOT NULL;

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
