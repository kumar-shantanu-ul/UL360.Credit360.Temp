-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=37
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
UPDATE csr.flow_alert_class
   SET on_save_helper_sp = 'csr.flow_pkg.OnCreateSupplierFlowHelpers'
 WHERE flow_alert_class = 'supplier';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
