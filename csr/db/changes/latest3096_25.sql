-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=25
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
BEGIN
	INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
	VALUES (36, 'permit', 'Surrendered Acknowledged');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_pkg
@../csr_data_pkg

@../compliance_body
@../flow_body
@../compliance_setup_body

@update_tail
