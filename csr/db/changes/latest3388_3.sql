-- Please update version.sql too -- this keeps clean builds in sync
define version=3388
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.flow_item ADD (
	auto_failure_count	NUMBER(4) DEFAULT 0 NOT NULL
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
@../flow_pkg
@../flow_body

@update_tail
