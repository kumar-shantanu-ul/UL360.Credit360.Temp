-- Please update version.sql too -- this keeps clean builds in sync
define version=3460
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE aspen2.application ADD (MEGA_MENU_ENABLED NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE aspen2.application ADD CONSTRAINT CK_MEGA_MENU_ENABLED CHECK (MEGA_MENU_ENABLED IN (0,1));
ALTER TABLE csrimp.aspen2_application ADD (MEGA_MENU_ENABLED NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.aspen2_application ADD CONSTRAINT CK_MEGA_MENU_ENABLED CHECK (MEGA_MENU_ENABLED IN (0,1));

UPDATE aspen2.application a
   SET mega_menu_enabled = (SELECT use_beta_menu FROM csr.customer WHERE app_sid = a.app_sid)
 WHERE EXISTS (SELECT 1 FROM csr.customer WHERE app_sid = a.app_sid);

ALTER TABLE csr.customer DROP COLUMN use_beta_menu;
ALTER TABLE csr.customer DROP COLUMN preview_beta_menu;

ALTER TABLE csrimp.customer DROP COLUMN use_beta_menu;
ALTER TABLE csrimp.customer DROP COLUMN preview_beta_menu;


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
@../../../aspen2/db/aspenapp_body
@../branding_pkg
@../branding_body
@../customer_body
@../schema_body
@../csrimp/imp_body

@update_tail
