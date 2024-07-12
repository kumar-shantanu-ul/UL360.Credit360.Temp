-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=23
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
create or replace package aspen2.timezone_pkg as end;
/
grant execute on aspen2.timezone_pkg to csr, web_user;

@../../../aspen2/db/timezone_pkg
@../../../aspen2/db/timezone_body

@update_tail
