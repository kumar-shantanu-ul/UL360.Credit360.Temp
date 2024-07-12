-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=5
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
ALTER TABLE csr.customer ADD dataexplorerperiodextension NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD dataexplorerperiodextension NUMBER(2)  DEFAULT 1 NOT NULL;

-- ** New package grants **

-- *** Packages ***

@update_tail
