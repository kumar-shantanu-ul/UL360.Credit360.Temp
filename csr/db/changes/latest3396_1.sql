-- Please update version.sql too -- this keeps clean builds in sync
define version=3396
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.period_set
ADD CONSTRAINT uk_period_set_label UNIQUE (app_sid, label);

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
@../period_pkg

@../period_body

@update_tail
