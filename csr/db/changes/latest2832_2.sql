-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Data changes ***
-- RLS
-- Data

-- ** New package grants **

-- *** Packages ***

@../schema_pkg
@../schema_body

@update_tail
