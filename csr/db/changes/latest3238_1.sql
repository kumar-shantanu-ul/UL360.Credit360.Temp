-- Please update version.sql too -- this keeps clean builds in sync
define version=3238
define minor_version=1
@update_header

/*
 * Copied from sr99_data.sql, which was run as a separate script after
 * the RC-99 deployment to remove redundant data.
 *
 * Included for completeness for any environment where that script
 * wasn't run. Will do nothing if already executed.
 */
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

@update_tail
