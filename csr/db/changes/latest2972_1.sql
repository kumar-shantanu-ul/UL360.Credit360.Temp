-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD (
    DELEG_DROPDOWN_THRESHOLD           NUMBER(10)         DEFAULT 4 NOT NULL
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_data_pkg
@..\csr_data_body
@..\customer_body

@update_tail
