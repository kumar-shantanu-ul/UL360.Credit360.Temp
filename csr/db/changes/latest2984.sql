-- Please update version.sql too -- this keeps clean builds in sync
define version=2984
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
UPDATE csr.flow_alert_class
SET on_save_helper_sp = 'csr.flow_pkg.OnCreateAuditFlow'
WHERE flow_alert_class = 'audit';


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_helper_pkg
@../flow_pkg

@../audit_helper_body
@../flow_body


@update_tail
