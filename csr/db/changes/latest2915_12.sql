-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=12
@update_header

--ALTER TABLE csr.est_building DROP COLUMN ignored;
--ALTER TABLE csr.est_building DROP CONSTRAINT ck_est_building_ignored;

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.est_building ADD (
	ignored NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_est_building_ignored CHECK (ignored IN (0, 1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
create or replace package csr.energy_star_account_pkg as end;
/
grant execute on csr.energy_star_account_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_pkg
@../energy_star_account_pkg

@../energy_star_body
@../energy_star_account_body
@../enable_body
@../property_body

@update_tail
