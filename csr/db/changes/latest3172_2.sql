-- Please update version.sql too -- this keeps clean builds in sync
define version=3172
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
drop sequence aspen2.profile_id_seq;
drop table aspen2.profile_step;
drop table aspen2.profile;
drop package aspen2.profile_pkg;

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

@update_tail
