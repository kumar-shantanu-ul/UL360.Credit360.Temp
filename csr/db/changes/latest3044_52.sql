-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=52
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer ADD (
	CALC_SUM_TO_DT_CUST_YR_START NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CALC_SUM_TO_DT_CUST_YR CHECK (CALC_SUM_TO_DT_CUST_YR_START IN (0,1))
);

ALTER TABLE csrimp.customer ADD (
	CALC_SUM_TO_DT_CUST_YR_START NUMBER(1) NOT NULL,
	CONSTRAINT CK_CALC_SUM_TO_DT_CUST_YR CHECK (CALC_SUM_TO_DT_CUST_YR_START IN (0,1))
);

update csr.customer set CALC_SUM_TO_DT_CUST_YR_START = 1 where name = 'firstgroup.credit360.com';

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
@../customer_body

@update_tail
