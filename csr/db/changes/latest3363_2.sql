-- Please update version.sql too -- this keeps clean builds in sync
define version=3363
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
DELETE FROM csr.flow_state_nature
 WHERE flow_state_nature_id = 38;

UPDATE csr.flow_alert_class
   SET helper_pkg = 'csr.flow_helper_pkg'
 WHERE flow_alert_class LIKE 'disclosure%';

UPDATE csr.flow_alert_class
   SET flow_alert_class = 'disclosureassignment',
	   label = 'Disclosure Assignment'
 WHERE flow_alert_class = 'disclosuredelegation';

INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label)
VALUES (38, 'disclosureassignment', 'Promoted to Approved');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

DECLARE
	v_count NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM all_objects
	 WHERE owner = 'CSR'
	   AND object_type = 'PACKAGE'
	   AND object_name = 'DISCLOSURE_FLOW_HELPER_PKG';
	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'DROP PACKAGE CSR.DISCLOSURE_FLOW_HELPER_PKG';
	END IF;
END;
/

@../flow_helper_pkg
@../flow_helper_body

@update_tail
