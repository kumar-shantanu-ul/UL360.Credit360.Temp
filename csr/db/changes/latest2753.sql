-- Please update version.sql too -- this keeps clean builds in sync
define version=2753
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT ON security.act TO chain;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\chain\type_capability_body

@update_tail
