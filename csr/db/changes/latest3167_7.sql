-- Please update version.sql too -- this keeps clean builds in sync
define version=3167
define minor_version=7
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

BEGIN
	UPDATE csr.customer SET helper_assembly = 'Centrica.Helper' WHERE app_sid IN (SELECT app_sid FROM csr.customer WHERE host = 'centrica.credit360.com');
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
