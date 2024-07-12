-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS
ALTER TABLE csr.customer DROP COLUMN dataexplorerperiodextension;
ALTER TABLE csrimp.customer DROP COLUMN dataexplorerperiodextension;

ALTER TABLE csr.customer ADD data_explorer_period_extension NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_period_extension NUMBER(2) NOT NULL;

-- ** New package grants **

-- *** Packages ***
@..\customer_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
