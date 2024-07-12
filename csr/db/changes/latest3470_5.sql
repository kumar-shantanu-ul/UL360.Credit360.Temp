-- Please update version.sql too -- this keeps clean builds in sync
define version=3470
define minor_version=5
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
	UPDATE csr.customer SET helper_assembly = NULL WHERE helper_assembly IN ('Centrica.Helper', 'Tyson.Helper');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
