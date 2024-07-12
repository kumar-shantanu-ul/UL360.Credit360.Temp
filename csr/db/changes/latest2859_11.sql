-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.TAB ADD (
  IS_HIDEABLE NUMBER(1) DEFAULT 1 NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
-- /cvs/csr/db/create_views.sql
CREATE OR REPLACE FORCE VIEW CSR.V$TAB_USER (TAB_ID, APP_SID, LAYOUT, NAME, IS_SHARED, IS_HIDEABLE, OVERRIDE_POS, USER_SID, POS, IS_OWNER, IS_HIDDEN, PORTAL_GROUP) AS 
	SELECT t.TAB_ID, t.APP_SID, t.LAYOUT, t.NAME, t.IS_SHARED, t.IS_HIDEABLE, t.OVERRIDE_POS, tu.USER_SID, tu.POS, tu.IS_OWNER, tu.IS_HIDDEN, t.PORTAL_GROUP
	  FROM TAB t, TAB_USER tu
	 WHERE t.TAB_ID = tu.TAB_ID;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@../portlet_pkg
@../approval_dashboard_pkg

@../portlet_body
@../approval_dashboard_body
@../enable_body
@../chain/setup_body

@update_tail
