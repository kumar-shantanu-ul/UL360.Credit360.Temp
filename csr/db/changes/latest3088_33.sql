-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.issue ADD (
	notified_overdue NUMBER(1) DEFAULT 0,
	CONSTRAINT chk_notified_overdue CHECK (notified_overdue IN (0,1))
);

ALTER TABLE csrimp.issue ADD (notified_overdue NUMBER(1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (34, 'condition', 'Action required');

UPDATE csr.flow_alert_class 
SET helper_pkg =  'csr.compliance_pkg'
WHERE flow_alert_class = 'condition';

UPDATE csr.issue 
   SET notified_overdue = 1
 WHERE due_dtm < SYSDATE;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../csr_data_pkg
@../flow_pkg
@../issue_pkg

@../csrimp/imp_body
@../compliance_body
@../compliance_setup_body
@../flow_body
@../issue_body
@../schema_body

@update_tail
