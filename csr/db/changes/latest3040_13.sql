-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
drop package csr.diary_pkg;
drop table csr.diary_event_group;
drop table csr.diary_event;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_pkg
@../csrimp/imp_body
@../schema_pkg
@../schema_body

@update_tail
