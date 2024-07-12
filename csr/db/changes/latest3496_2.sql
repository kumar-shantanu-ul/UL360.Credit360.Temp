-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=2
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
UPDATE csr.auto_imp_core_data_settings
   SET all_or_nothing = 0
 WHERE all_or_nothing != 0;

UPDATE csr.auto_imp_core_data_settings
   SET requires_validation_step = 0
 WHERE requires_validation_step != 0;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
