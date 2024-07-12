-- Please update version.sql too -- this keeps clean builds in sync
define version=3426
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.auto_exp_class_qc_settings ADD encoding_name VARCHAR2(255);

BEGIN
	security.user_pkg.logonadmin;
	UPDATE csr.auto_exp_class_qc_settings SET encoding_name = 'Windows-1252';
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

@../automated_export_pkg
@../automated_export_body

@update_tail
