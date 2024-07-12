-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.issue_type ADD (
	region_is_mandatory NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_iss_type_reg_is_mand CHECK (region_is_mandatory IN (0,1))
);

ALTER TABLE csrimp.issue_type ADD region_is_mandatory NUMBER(1) DEFAULT 0 NOT NULL;

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

@../issue_pkg
@../issue_body
@../schema_body
@../csrimp/imp_body

@update_tail
