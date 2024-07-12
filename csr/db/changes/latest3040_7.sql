-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
create or replace package csr.permission_pkg as end;
/
grant execute on csr.permission_pkg to web_user;
grant execute on aspen2.aspen_user_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body
@../permission_pkg
@../permission_body

@update_tail
