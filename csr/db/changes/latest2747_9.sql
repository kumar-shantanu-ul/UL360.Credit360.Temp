-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.PORTAL_DASHBOARD (
  APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  PORTAL_SID            NUMBER(10, 0)     NOT NULL,
  PORTAL_GROUP          VARCHAR2(50)      NOT NULL,
  MENU_SID              NUMBER(10, 0),
  MESSAGE               VARCHAR2(2048),
  CONSTRAINT PK_PORTAL_DASHBOARD_SID PRIMARY KEY (APP_SID, PORTAL_SID),
  CONSTRAINT UK_PORTAL_DASHBOARD_GROUP UNIQUE (APP_SID, PORTAL_GROUP),
  CONSTRAINT UK_PORTAL_MENU_SID UNIQUE (APP_SID, MENU_SID)
);

-- Alter tables

-- *** Grants ***


-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data
DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRPortalDashboard', 'csr.portal_dashboard_pkg', null, v_Id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (48, 'Multiple dashboards', 'EnablePortalDashboards', 'Enables the ability to create multiple dashboards. Adds a menu item to the admin menu.', 0);

-- ** New package grants **
create or replace package csr.portal_dashboard_pkg as
procedure dummy;
end;
/
create or replace package body csr.portal_dashboard_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on csr.portal_dashboard_pkg to web_user;
grant execute on CSR.portal_dashboard_pkg to security;

-- *** Packages ***
@..\portal_dashboard_pkg
@..\portal_dashboard_body
@..\portlet_body
@..\enable_pkg
@..\enable_body

@update_tail
