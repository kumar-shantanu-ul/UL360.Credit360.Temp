-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD DIVISIBILITY_BUG NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_DIVISIBILITY_BUG CHECK (DIVISIBILITY_BUG IN (0,1));

UPDATE CSR.CUSTOMER SET DIVISIBILITY_BUG = 1 WHERE MERGED_SCENARIO_RUN_SID IS NOT NULL;

ALTER TABLE CSRIMP.CUSTOMER ADD DIVISIBILITY_BUG NUMBER(1, 0) NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_DIVISIBILITY_BUG CHECK (DIVISIBILITY_BUG IN (0,1));

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
@../schema_body
@../csrimp/imp_body

@update_tail
