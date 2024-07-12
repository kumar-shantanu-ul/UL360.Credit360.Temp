-- Please update version.sql too -- this keeps clean builds in sync
define version=3195
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

BEGIN
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (37, 'campaign', 'Promoted to Submission');
EXCEPTION WHEN dup_val_on_index THEN
	NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
