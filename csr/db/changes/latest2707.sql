-- Please update version.sql too -- this keeps clean builds in sync
define version=2707
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT EXECUTE on csr.region_pkg TO CT;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../region_pkg
@../ct/hotspot_pkg

@../region_body
@../ct/hotspot_body

@update_tail
