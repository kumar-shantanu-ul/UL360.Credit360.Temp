-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD (
    TEAR_OFF_DELEG_HEADER           NUMBER(1)         DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CUST_TEAR_OFF_DELEG CHECK (TEAR_OFF_DELEG_HEADER IN (0,1))
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
