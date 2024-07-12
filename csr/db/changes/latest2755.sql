-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.scheduled_stored_proc DROP COLUMN args CASCADE CONSTRAINTS;

ALTER TABLE csr.scheduled_stored_proc ADD CONSTRAINT pk_ssp PRIMARY KEY (app_sid, sp);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../ssp_pkg
@../ssp_body

@update_tail
