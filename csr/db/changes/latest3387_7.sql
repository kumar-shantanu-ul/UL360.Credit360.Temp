-- Please update version.sql too -- this keeps clean builds in sync
define version=3387
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

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
@../sustain_essentials_pkg

@../sustain_essentials_body
@../indicator_api_body

@update_tail
