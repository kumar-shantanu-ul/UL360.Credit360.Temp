-- Please update version.sql too -- this keeps clean builds in sync
define version=3069
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE csr.tt_company_region_role (
	company_sid					NUMBER(10) NOT NULL,
	region_sid					NUMBER(10) NOT NULL,
	role_sid					NUMBER(10) NOT NULL,
	active						NUMBER(1) NOT NULL,
	deleted						NUMBER(1) NOT NULL
) ON COMMIT DELETE ROWS;

-- Alter tables

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
@../supplier_body

@update_tail
