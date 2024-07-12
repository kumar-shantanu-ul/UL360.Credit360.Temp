-- Please update version.sql too -- this keeps clean builds in sync
define version=2920
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.delegation_layout ADD (VALID NUMBER(1) DEFAULT 1 NOT NULL);
ALTER TABLE csrimp.delegation_layout ADD (VALID NUMBER(1) DEFAULT 1 NOT NULL);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\delegation_pkg
@..\delegation_body
@..\schema_body

@..\csrimp\imp_body

@update_tail
