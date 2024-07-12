-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.section_val ADD (
    period_set_id           NUMBER(10, 0),
    period_interval_id      NUMBER(10, 0)
);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
--@..\create_views
CREATE OR REPLACE VIEW csr.v$corp_rep_capability AS
	SELECT sec.app_sid, sec.section_sid, fsrc.flow_capability_id,
	   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
	   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM csr.section sec
	  JOIN csr.section_module secmod ON sec.app_sid = secmod.app_sid
	   AND sec.module_root_sid = secmod.module_root_sid
	  JOIN csr.flow_item fi ON sec.app_sid = fi.app_sid
	   AND sec.flow_item_id = fi.flow_item_id
	  JOIN csr.flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid
	   AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN csr.region_role_member rrm ON sec.app_sid = rrm.app_sid
	   AND secmod.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	 WHERE sec.active = 1
	   AND rrm.role_sid IS NOT NULL
	 GROUP BY sec.app_sid, sec.section_sid, fsrc.flow_capability_id;
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../section_pkg
@../section_body
@../section_root_body

@update_tail
