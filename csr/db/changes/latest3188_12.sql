-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=12
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
DECLARE
	PROCEDURE IgnoreDupe(
		in_insert_statement	VARCHAR2
	)
	AS
	BEGIN
		BEGIN
			EXECUTE IMMEDIATE in_insert_statement;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
			WHEN OTHERS THEN
				RAISE;
		END;
	END;
BEGIN
	IgnoreDupe('INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES (''regulation'', ''Regulation'', ''CSR.COMPLIANCE_PKG'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (5, ''regulation'', ''New'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (6, ''regulation'', ''Updated'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (7, ''regulation'', ''Action Required'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (8, ''regulation'', ''Compliant'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (9, ''regulation'', ''Not applicable'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (10, ''regulation'', ''Retired'')');
	IgnoreDupe('INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES (''requirement'', ''Requirement'', ''CSR.COMPLIANCE_PKG'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (11, ''requirement'', ''New'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (12, ''requirement'', ''Updated'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (13, ''requirement'', ''Action Required'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (14, ''requirement'', ''Compliant'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (15, ''requirement'', ''Not applicable'')');
	IgnoreDupe('INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (16, ''requirement'', ''Retired'')');
	IgnoreDupe('INSERT INTO csr.module_param (module_id, param_name, pos, param_hint) VALUES (79, ''Create regulation workflow?'', 0, ''(Y/N)'')');
	IgnoreDupe('INSERT INTO csr.module_param (module_id, param_name, pos, param_hint) VALUES (79, ''Create requirement workflow?'', 1, ''(Y/N)'')');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
