-- Please update version.sql too -- this keeps clean builds in sync
--define version=xxxx
--define minor_version=0
--@update_header

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

DELETE FROM csr.flow_item_gen_alert_archive
 WHERE (app_sid, flow_item_generated_alert_id) IN (
	 SELECT app_sid, flow_item_generated_alert_id
	   FROM csr.flow_item_generated_alert
 );

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

--@update_tail
