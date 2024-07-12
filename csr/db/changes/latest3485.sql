-- Please update version.sql too -- this keeps clean builds in sync
define version=3485
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSRIMP.user_table ADD (
    ACCOUNT_EXPIRY_ENABLED   NUMBER(1, 0)     NOT NULL CHECK (ACCOUNT_EXPIRY_ENABLED IN (0,1)),
    ACCOUNT_DISABLED_DTM     DATE
);


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
@../schema_body
@../csrimp/imp_body

@update_tail
