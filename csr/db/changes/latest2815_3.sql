-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=3
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

ALTER TABLE CSR.EXPORT_FEED ADD (ALERT_RECIPIENTS VARCHAR(1024));

-- Data


-- ** New package grants **

-- *** Packages ***
@../export_feed_pkg
@../export_feed_body

@update_tail
