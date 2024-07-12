-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$my_compliance_items AS
	SELECT cir.compliance_item_id, cir.region_sid, cir.flow_item_id
	  FROM csr.compliance_item_region cir
	  JOIN csr.flow_item fi ON cir.app_sid = fi.app_sid AND cir.flow_item_id = fi.flow_item_id
	 WHERE  (EXISTS (
			SELECT 1
			  FROM csr.region_role_member rrm
			  JOIN csr.flow_state_role fsr ON rrm.app_sid = fsr.app_sid AND fsr.role_sid = rrm.role_sid
			 WHERE rrm.app_sid = cir.app_sid
			   AND rrm.region_sid = cir.region_sid
			   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND fsr.flow_state_id = fi.current_state_id
		)
		OR EXISTS (
			SELECT 1
			  FROM csr.flow_state_role fsr
			  JOIN security.act act ON act.sid_id = fsr.group_sid
			 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
			   AND fsr.flow_state_id = fi.current_state_id
		)
);

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
VALUES (1062,'Compliance levels','Credit360.Portlets.ComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/ComplianceLevels.js');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\compliance_pkg

@@..\enable_body
@@..\compliance_body
@@..\compliance_register_report_body

@update_tail
