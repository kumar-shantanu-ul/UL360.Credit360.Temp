-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=42
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.section_fact_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOORDER
;

-- Alter tables
ALTER TABLE csr.section_module ADD (
	show_fact_icon	NUMBER(1, 0)	DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.section_module ADD (
	show_fact_icon	NUMBER(1, 0)	NULL
);

UPDATE csrimp.section_module SET show_fact_icon = 0;
ALTER TABLE csrimp.section_module MODIFY show_fact_icon NOT NULL;

ALTER TABLE csr.section_val ADD (
	entry_type	VARCHAR2(100)	DEFAULT 'MANUAL' NOT NULL
);

ALTER TABLE csr.section_val ADD CONSTRAINT CHK_SEC_VAL_ENTRY_TYPE 
	CHECK (entry_type IN ('MANUAL', 'PREVIOUS', 'INDICATOR'));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
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
	  LEFT JOIN csr.superadmin sa ON sa.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE sec.active = 1
	   AND (rrm.role_sid IS NOT NULL OR sa.csr_user_sid IS NOT NULL)
	 GROUP BY sec.app_sid, sec.section_sid, fsrc.flow_capability_id;

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (21, 'corpreporter', 'Edit indicator fact', 1, 0); --csr_data_pkg.flow_cap_corp_rep_edit_fact

INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (22, 'corpreporter', 'Clear indicator fact', 1, 0); --csr_data_pkg.flow_cap_corp_rep_clear_fact

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\section_pkg
@..\section_body
@..\section_root_pkg
@..\section_root_body
@..\csrimp\imp_body
@..\csr_data_pkg

@update_tail
