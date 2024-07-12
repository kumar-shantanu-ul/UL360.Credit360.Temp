-- Please update version.sql too -- this keeps clean builds in sync
define version=3238
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
exec security.user_pkg.logonadmin;

ALTER TABLE csr.flow_item_generated_alert MODIFY created_dtm DEFAULT SYSDATE;

UPDATE csr.flow_item_generated_alert 
   SET created_dtm = NVL(processed_dtm, SYSDATE)
 WHERE created_dtm IS NULL;

ALTER TABLE csr.flow_item_generated_alert MODIFY created_dtm NOT NULL;

ALTER TABLE csr.flow_item_generated_alert MODIFY app_sid  DEFAULT SYS_CONTEXT('SECURITY','APP');

ALTER TABLE csr.flow_item_gen_alert_archive MODIFY created_dtm DEFAULT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
