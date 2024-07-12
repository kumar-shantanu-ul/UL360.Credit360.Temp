-- Please update version.sql too -- this keeps clean builds in sync
define version=3214
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.flow_alert_class ADD (
	allow_create	NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT CHK_FLOW_ALERT_CLASS_CREATE CHECK (ALLOW_CREATE IN (0, 1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.flow_alert_class
   SET allow_create = 0
 WHERE flow_alert_class IN ('regulation', 'requirement', 'permit', 'application', 'condition');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_body

@update_tail
