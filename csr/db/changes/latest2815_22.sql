-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=22
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

@../../../aspen2/db/timezone_pkg
@../../../aspen2/db/timezone_body

@update_tail
