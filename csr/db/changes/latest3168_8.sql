-- Please update version.sql too -- this keeps clean builds in sync
define version=3168
define minor_version=8
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

create or replace package csr.measure_api_pkg as end;
/
grant execute on csr.measure_api_pkg to web_user;
-- *** Conditional Packages ***

-- *** Packages ***

@../measure_api_pkg
@../measure_api_body

@update_tail