-- Please update version.sql too -- this keeps clean builds in sync
define version=2720
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../chain/invitation_pkg
@../chain/invitation_body

@update_tail
