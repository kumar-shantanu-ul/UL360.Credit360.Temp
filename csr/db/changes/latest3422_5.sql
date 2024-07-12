-- Please update version.sql too -- this keeps clean builds in sync
define version=3422
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.automated_export_class MODIFY lookup_key VARCHAR2(255);

BEGIN
	security.user_pkg.logonadmin;
	UPDATE csr.automated_export_class SET lookup_key = automated_export_class_sid;
END;
/

CREATE UNIQUE INDEX csr.uk_lookup_exp_class ON csr.automated_export_class(app_sid, UPPER(lookup_key));

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
