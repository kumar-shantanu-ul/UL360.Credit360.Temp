-- Please update version.sql too -- this keeps clean builds in sync
define version=3039
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- Ensuring no one enabled mapping icons.
exec security.user_pkg.logonadmin();

UPDATE csr.section_module
   SET show_fact_icon = 0
 WHERE show_fact_icon = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
