-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.version ADD (
	minor_version	NUMBER(10)
);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***


@update_tail
