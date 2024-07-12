-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=20
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

-- Data

-- ** New package grants **
create or replace package csr.customer_pkg as
procedure dummy;
end;
/
create or replace package body csr.customer_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on csr.customer_pkg to web_user;

-- *** Packages ***
@..\customer_pkg
@..\csr_app_pkg
@..\customer_body
@..\csr_app_body

@update_tail
