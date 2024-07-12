-- Please update version.sql too -- this keeps clean builds in sync
define version=3311
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
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_ID, LABEL, AUDIT_TYPE_GROUP_ID ) VALUES (203, 'Chain Filter', 4);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg

@../chain/filter_body

@update_tail
