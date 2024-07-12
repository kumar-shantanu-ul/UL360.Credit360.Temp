-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=19
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
INSERT INTO cms.col_type(col_type, description)
VALUES(42, 'Flow state lookup key');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\..\..\aspen2\cms\db\tab_pkg

@update_tail
