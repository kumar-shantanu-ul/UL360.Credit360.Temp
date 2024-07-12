CREATE OR REPLACE PACKAGE BODY csr.campaign_flow_helper_pkg AS

PROCEDURE GenerateInvolmTypeAlertEntries(
	in_flow_item_id 				IN flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN security.security_pkg.T_SID_ID,
	in_flow_transition_alert_id  	IN flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id  	IN flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 			IN flow_state_log.flow_state_log_id%TYPE,
	in_subject_override				IN flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN flow_item_generated_alert.body_override%TYPE DEFAULT NULL
)
AS
BEGIN
	--non restricted purchaser pseudo-roles
	INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
		from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
	SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
		in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
	  FROM (
		SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
		  FROM quick_survey_response qsr
	 	  JOIN flow_item fi ON qsr.survey_response_id = fi.survey_response_id
	  	  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  JOIN supplier s ON rsr.region_sid = s.region_sid
		  JOIN chain.supplier_relationship sr ON sr.supplier_company_sid = s.company_sid
		  JOIN chain.company pc ON pc.company_sid = sr.purchaser_company_sid
		  JOIN chain.company sc ON sc.company_sid = sr.supplier_company_sid
	 	  JOIN chain.supplier_involvement_type sit
		    ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
		   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
		   AND (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_ANY
		    OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_PRIMARY AND sr.is_primary = 1)
		    OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_OWNER AND pc.company_sid = sc.parent_sid)
			)
		  JOIN chain.v$company_user cu ON sr.purchaser_company_sid = cu.company_sid   
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND sit.flow_involvement_type_id = in_flow_involvement_type_id
		   AND sr.active = 1
		   AND sr.deleted = 0
		   AND sit.restrict_to_role_sid IS NULL
		   AND qsr.qs_campaign_sid IS NOT NULL
		   AND NOT EXISTS(
			SELECT 1 
			  FROM csr.flow_item_generated_alert figa
			 WHERE figa.app_sid = sr.app_sid
			   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
			   AND figa.flow_state_log_id = in_flow_state_log_id
			   AND figa.to_user_sid = cu.user_sid
		  )
	 );
	
	--RRM (on purchaser region) restricted purchaser pseudo-roles
	INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
		from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
	SELECT app_sid, csr.flow_item_gen_alert_id_seq.nextval, in_flow_transition_alert_id, 
		in_set_by_user_sid, to_user_sid, NULL, in_flow_item_id, in_flow_state_log_id
	  FROM (
		SELECT DISTINCT sr.app_sid, cu.user_sid to_user_sid
		  FROM quick_survey_response qsr
	 	  JOIN flow_item fi ON qsr.survey_response_id = fi.survey_response_id
	  	  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  JOIN supplier s ON rsr.region_sid = s.region_sid
		  JOIN chain.supplier_relationship sr ON sr.supplier_company_sid = s.company_sid
		  JOIN chain.company pc ON pc.company_sid = sr.purchaser_company_sid
		  JOIN chain.company sc ON sc.company_sid = sr.supplier_company_sid
	 	  JOIN chain.supplier_involvement_type sit
		    ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
		   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
		   AND (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_ANY
		    OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_PRIMARY AND sr.is_primary = 1)
		    OR (sit.purchaser_type = chain.chain_pkg.PURCHASER_TYPE_OWNER AND pc.company_sid = sc.parent_sid)
			)
		  JOIN supplier ps ON ps.company_sid = sr.purchaser_company_sid
		  JOIN chain.v$company_user cu ON sr.purchaser_company_sid = cu.company_sid
		  JOIN region_role_member rrm
			ON rrm.region_sid = ps.region_sid
		   AND rrm.user_sid = cu.user_sid
		   AND rrm.role_sid = sit.restrict_to_role_sid
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND sit.flow_involvement_type_id = in_flow_involvement_type_id
		   AND sr.active = 1
		   AND sr.deleted = 0
		   AND sit.restrict_to_role_sid IS NOT NULL
		   AND qsr.qs_campaign_sid IS NOT NULL
		   AND NOT EXISTS(
			SELECT 1 
			  FROM csr.flow_item_generated_alert figa
			 WHERE figa.app_sid = sr.app_sid
			   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
			   AND figa.flow_state_log_id = in_flow_state_log_id
			   AND figa.to_user_sid = cu.user_sid
		  )
	 );
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
) RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT rsr.region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM quick_survey_response qsr
	  JOIN flow_item fi ON qsr.survey_response_id = fi.survey_response_id
	  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
	   AND fi.flow_item_id = in_flow_item_id
	   AND qsr.qs_campaign_sid IS NOT NULL
	 UNION 
	SELECT fir.region_sid
	  FROM flow_item_region fir
	 WHERE fir.flow_item_id = in_flow_item_id;

	RETURN v_region_sids_t;
END;

END campaign_flow_helper_pkg;
/
