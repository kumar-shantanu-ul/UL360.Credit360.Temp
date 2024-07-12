-- Please update version.sql too -- this keeps clean builds in sync
define version=3313
define minor_version=3
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
UPDATE csr.initiatives_options
  SET metrics_end_year = 2030
 WHERE metrics_end_year < 2030;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***


@update_tail
