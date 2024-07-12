-- Please update version.sql too -- this keeps clean builds in sync
define version=2674
@update_header

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (43, 'Approval dashboards', 'EnableApprovalDashboards', 'Enables approval dashboards. Menus, pages and portlets. Requires scenarios.', 1);

-- *** Packages ***

@../enable_pkg
@../enable_body

@update_tail