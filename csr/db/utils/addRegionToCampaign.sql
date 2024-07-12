DECLARE
	in_qs_campaign_sid		security.security_pkg.T_SID_ID := 21908342; -- update this line
	in_host					varchar2(256) := 'solvay.credit360.com'; -- update this line
	v_period_start_dtm		csr.qs_campaign.period_start_dtm%TYPE;
	v_period_end_dtm		csr.qs_campaign.period_end_dtm%TYPE;
	v_survey_sid			security.security_pkg.T_SID_ID;
	v_flow_sid				security.security_pkg.T_SID_ID;
	v_guid					csr.quick_survey_response.guid%TYPE;
	v_response_id			csr.quick_survey_response.survey_response_id%TYPE;
	v_flow_item_id			csr.flow_item.flow_item_id%TYPE;
	v_path					security.web_resource.path%TYPE;
BEGIN
	security.user_pkg.logonadmin(in_host);
	
	SELECT c.period_start_dtm, c.period_end_dtm, c.survey_sid, c.flow_sid, wr.path
	  INTO v_period_start_dtm, v_period_end_dtm, v_survey_sid, v_flow_sid, v_path
	  FROM csr.qs_campaign c
	  JOIN security.web_resource wr ON c.survey_sid = wr.sid_id
	 WHERE qs_campaign_sid = in_qs_campaign_sid;
	
	-- loop through additional regions required
	FOR r IN (
		SELECT 21435295 region_sid FROM dual -- update this line and add additional lines if required
		-- union select <next_region_sid> from dual
	) LOOP
		csr.quick_survey_pkg.NewCampaignResponse(in_qs_campaign_sid, r.region_sid, v_guid, v_response_id);
		csr.flow_pkg.AddQuickSurveyResponse(v_response_id, v_flow_sid, v_flow_item_id);
		dbms_output.put_line('https://'||in_host||v_path||'/'||v_response_id);
	END LOOP;
END;
/