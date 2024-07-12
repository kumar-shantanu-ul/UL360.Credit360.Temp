-- Please update version.sql too -- this keeps clean builds in sync
define version=3477
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.customer ADD (
	AUTO_ANONYMISATION_ENABLED         NUMBER(1,0)  DEFAULT 0  NOT NULL,
	INACTIVE_DAYS_BEFORE_ANONYMISATION NUMBER(10,0) DEFAULT 30 NOT NULL
);

ALTER TABLE csrimp.customer ADD (
    AUTO_ANONYMISATION_ENABLED         NUMBER(1,0)      NOT NULL,
	INACTIVE_DAYS_BEFORE_ANONYMISATION NUMBER(10,0)     NOT NULL
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
@../csr_data_pkg
@../csr_data_body
@../csrimp/imp_body
@../schema_body

@update_tail