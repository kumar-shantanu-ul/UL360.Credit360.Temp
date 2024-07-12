-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=36
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$all_purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.purchaser_company_sid, sr.supplier_company_sid,
		rrm.user_sid ct_role_user_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN v$company_user cu -- this will do for now, but it probably performs horribly
	    ON cu.company_sid = pc.company_sid
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = cu.user_sid
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.deleted = 0
	   AND sc.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL)
	 GROUP BY sit.flow_involvement_type_id, sr.purchaser_company_sid, sr.supplier_company_sid,
		rrm.user_sid;
-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1001 /* csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE */, 'campaign', 'Survey response', 0 /*Specific*/, 1 /*security_pkg.PERMISSION_READ*/);

	--move existing perms to flow_capabilitiees
	security.user_pkg.logonadmin;

	INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, group_sid,
		flow_involvement_type_id, permission_set)		 
	SELECT fsr.app_sid, csr.flow_state_rl_cap_id_seq.nextval, fsr.flow_state_id, 1001, fsr.role_sid, fsr.group_sid,
		NULL, DECODE(is_editable, 0, 1 /*security_pkg.PERMISSION_READ*/, 1 /*security_pkg.PERMISSION_READ*/ + 2 /*security_pkg.PERMISSION_WRITE*/)
	  FROM csr.flow_state_role fsr
	  JOIN csr.flow_state fs ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
	  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
	 WHERE f.flow_alert_class = 'campaign';

	--we don't need is_editable for campaigns anymore
	UPDATE csr.flow_state_role
	   SET is_editable = 0
	 WHERE flow_state_id IN (
		SELECT fs.flow_state_id
		  FROM csr.flow_state fs
		  JOIN csr.flow f ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid
	 	 WHERE f.flow_alert_class = 'campaign')
	   AND is_editable = 1;

	INSERT INTO csr.flow_inv_type_alert_class(app_sid, flow_involvement_type_id, flow_alert_class)
	SELECT cfac.app_sid, 1001 /*FLOW_INV_TYPE_PURCHASER*/, cfac.flow_alert_class
	  FROM csr.customer_flow_alert_class cfac
	 WHERE cfac.flow_alert_class IN ('audit', 'campaign')
	   AND EXISTS (
			SELECT 1
			  FROM csr.flow_involvement_type fit
			 WHERE fit.app_sid = cfac.app_sid
			   AND fit.flow_involvement_type_id = 1001
	   )
	   AND NOT EXISTS(
			SELECT 1
			  FROM csr.flow_inv_type_alert_class fitac
			 WHERE fitac.app_sid = cfac.app_sid
			   AND fitac.flow_alert_class = cfac.flow_alert_class
			   AND fitac.flow_involvement_type_id = 1001
	   );
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../quick_survey_pkg
@../campaign_pkg

@../enable_body
@../campaign_body
@../quick_survey_body
@../chain/setup_body

@update_tail
