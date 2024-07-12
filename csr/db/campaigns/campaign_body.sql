CREATE OR REPLACE PACKAGE BODY campaigns.campaign_pkg AS

PROCEDURE CreateObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID,
	in_class_id					IN  security.security_pkg.T_CLASS_ID,
	in_name						IN  security.security_pkg.T_SO_NAME,
	in_parent_sid_id			IN  security.security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID,
	in_new_name					IN  security.security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID
)
AS
BEGIN
	-- TODO: We need to set a deleted flag against the campaign
	NULL;
END;

PROCEDURE MoveObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN  security.security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashCampaign(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
)
AS
	v_trash_sid					security.security_pkg.T_SID_ID;
	v_campaign_name				campaign.name%TYPE;

BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Delete access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	-- TODO: US16566 - set a deleted flag/dtm against the campaign and remove trash stuff
	SELECT trash_sid
	  INTO v_trash_sid
	  FROM csr.customer
	 WHERE app_sid = security.security_pkg.GetApp;

	SELECT name
	  INTO v_campaign_name
	  FROM campaign
	 WHERE campaign_sid = in_campaign_sid;

	csr.trash_pkg.TrashObject(security.security_pkg.GetAct, in_campaign_sid, v_trash_sid, v_campaign_name);
END;

PROCEDURE GetCampaign (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	OPEN out_cur FOR
		SELECT c.campaign_sid, c.name, c.table_sid, c.filter_sid, c.survey_sid, c.frame_id, c.subject, c.body,
				c.send_after_dtm, c.status, c.sent_dtm, c.period_start_dtm, c.period_end_dtm, r.responses_submitted,
				r.responses_sent, c.audience_type, c.flow_sid, f.label flow_label, c.skip_overlapping_regions,
				NVL(t.description, t.oracle_table) table_name, fil.name filter_name, c.inc_regions_with_no_users,
				CASE WHEN c.status IN ('sending', 'emailing') OR (c.status='pending' AND (c.send_after_dtm IS NULL OR c.send_after_dtm < SYSDATE)) THEN 1 ELSE 0 END currently_active,
				c.carry_forward_answers, c.send_to_column_sid, c.region_column_sid, so.parent_sid_id parent_sid,
				c.response_column_sid, c.tag_lookup_key_column_sid, c.is_system_generated, c.customer_alert_type_id,
				c.campaign_end_dtm, c.send_alert, c.dynamic, c.resend, qsv.label survey_label
		  FROM campaign c
		  JOIN security.securable_object so ON c.campaign_sid = so.sid_id AND c.app_sid = so.application_sid_id
		  LEFT JOIN csr.quick_survey qs ON qs.survey_sid = c.survey_sid
		  LEFT JOIN csr.quick_survey_version qsv ON qsv.survey_sid = qs.survey_sid AND qsv.survey_version = qs.current_version
		  LEFT JOIN csr.flow f ON c.flow_sid = f.flow_sid
		  LEFT JOIN cms.tab t ON c.table_sid = t.tab_sid
		  LEFT JOIN cms.filter fil ON c.filter_sid = fil.filter_sid
		  LEFT JOIN (
			SELECT qs_campaign_sid, count(submitted_dtm) responses_submitted, count(*) responses_sent
			  FROM csr.v$quick_survey_response
			 WHERE qs_campaign_sid IS NOT NULL
			 GROUP BY qs_campaign_sid
		  ) r ON c.campaign_sid = r.qs_campaign_sid
		 WHERE c.campaign_sid = in_campaign_sid;
END;

PROCEDURE GetRecipientViewXml (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: Should this just be part of the above?
	-- TODO: What if the filter has since been deleted? Right now we'd email everyone.
	OPEN out_cur FOR
		SELECT NVL(c.filter_xml, TO_CLOB(NVL(frm.form_xml, fil.filter_xml))) view_xml
		  FROM campaign c
		  LEFT JOIN cms.v$form frm ON c.filter_sid = frm.form_sid
		  LEFT JOIN cms.filter fil ON c.filter_sid = fil.filter_sid
		 WHERE campaign_sid = in_campaign_sid;
END;

PROCEDURE GetCampaignList (
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_act						security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_app						security.security_pkg.T_ACT_ID := security.security_pkg.GetApp;
	v_campaigns_sid				security.security_pkg.T_SID_ID;
	v_children_with_read_perm 	security.T_SO_DESCENDANTS_TABLE;
BEGIN
	BEGIN
		v_campaigns_sid := security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Campaigns');
		v_children_with_read_perm := security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act, v_campaigns_sid, security.security_pkg.PERMISSION_READ);
	EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
		-- If campaigns not enabled, return nothing
		NULL;
	END;
	
	OPEN out_cur FOR
		SELECT c.campaign_sid, c.name, c.table_sid, c.filter_sid, c.survey_sid, c.status, c.flow_sid, f.label flow_label,
				s.label survey_label
		  FROM campaign c
		  JOIN TABLE(v_children_with_read_perm) t ON t.sid_id = c.campaign_sid
		  LEFT JOIN csr.v$quick_survey s ON s.survey_sid = c.survey_sid
		  LEFT JOIN csr.flow f ON c.flow_sid = f.flow_sid
		 WHERE c.app_sid = security.security_pkg.GetApp
		 ORDER BY LOWER(c.name);

END;

PROCEDURE GetCampaigns (
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_act						security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_app						security.security_pkg.T_ACT_ID := security.security_pkg.GetApp;
	v_children_with_read_perm 	security.T_SO_TABLE;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(v_act, security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Campaigns'), security.security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'List contents access denied on App/Campaigns');
	END IF;

	v_children_with_read_perm := security.securableobject_pkg.GetChildrenWithPermAsTable(v_act, in_parent_sid, security.security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT c.campaign_sid, c.name, c.table_sid, c.filter_sid, c.survey_sid, c.frame_id,
				c.subject, c.body, c.send_after_dtm, c.status, c.sent_dtm, r.responses_submitted,
				r.responses_sent, c.audience_type, c.flow_sid, f.label flow_label,
				NVL(t.description, t.oracle_table) table_name, fil.name filter_name,
				CASE WHEN c.status IN ('sending', 'emailing') OR (c.status='pending' AND (c.send_after_dtm IS NULL OR c.send_after_dtm < SYSDATE)) THEN 1 ELSE 0 END currently_active,
				c.carry_forward_answers, c.send_to_column_sid, c.region_column_sid, so.parent_sid_id parent_sid,
				c.response_column_sid, c.tag_lookup_key_column_sid, c.is_system_generated, c.customer_alert_type_id, c.send_alert, c.dynamic, c.resend,
				s.label survey_label, c.campaign_end_dtm, c.period_start_dtm, c.period_end_dtm
		  FROM campaign c
		  JOIN TABLE(v_children_with_read_perm) t ON t.sid_id = c.campaign_sid
		  JOIN security.securable_object so ON c.campaign_sid = so.sid_id AND c.app_sid = so.application_sid_id
		  LEFT JOIN csr.v$quick_survey s ON s.survey_sid = c.survey_sid
		  LEFT JOIN csr.flow f ON c.flow_sid = f.flow_sid
		  LEFT JOIN cms.tab t ON c.table_sid = t.tab_sid
		  LEFT JOIN cms.filter fil ON c.filter_sid = fil.filter_sid
		  LEFT JOIN (
			SELECT qs_campaign_sid, count(submitted_dtm) responses_submitted, count(*) responses_sent
			  FROM csr.v$quick_survey_response
			 WHERE qs_campaign_sid IS NOT NULL
			 GROUP BY qs_campaign_sid
		  ) r ON c.campaign_sid = r.qs_campaign_sid
		 WHERE c.app_sid = security.security_pkg.GetApp
		   AND so.parent_sid_id = in_parent_sid
		 ORDER BY NVL(c.sent_dtm, SYSDATE) DESC;
END;

PROCEDURE GetCampaignPeriodsBySids(
	in_campaign_sids				IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_campaign_sids					security.T_SID_TABLE;
BEGIN

	v_campaign_sids := security.security_pkg.SidArrayToTable(in_campaign_sids);

	OPEN out_cur FOR
		SELECT c.campaign_sid, c.period_start_dtm, c.period_end_dtm
		  FROM campaign c
		  JOIN TABLE(v_campaign_sids) cs ON c.campaign_sid = cs.column_value;
END;

PROCEDURE SaveCampaign (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	in_name						IN	campaign.name%TYPE,
	in_audience_type			IN	campaign.audience_type%TYPE,
	in_table_sid				IN	security.security_pkg.T_SID_ID,
	in_filter_sid				IN	security.security_pkg.T_SID_ID,
	in_flow_sid					IN	security.security_pkg.T_SID_ID,
	in_inc_regions_w_no_users	IN	campaign.inc_regions_with_no_users%TYPE,
	in_skip_overlapping_regions	IN	campaign.skip_overlapping_regions%TYPE,
	in_survey_sid				IN	security.security_pkg.T_SID_ID,
	in_frame_id					IN	campaign.frame_id%TYPE,
	in_subject					IN	campaign.subject%TYPE,
	in_body						IN	campaign.body%TYPE,
	in_send_after_dtm			IN	campaign.send_after_dtm%TYPE,
	in_end_dtm					IN	campaign.campaign_end_dtm%TYPE,
	in_period_start_dtm			IN	campaign.period_start_dtm%TYPE,
	in_period_end_dtm			IN	campaign.period_end_dtm%TYPE,
	in_carry_forward_answers	IN	campaign.carry_forward_answers%TYPE,
	in_send_to_column_sid		IN	campaign.send_to_column_sid%TYPE,
	in_region_column_sid		IN	campaign.region_column_sid%TYPE,
	in_send_alert				IN	campaign.send_alert%TYPE,
	in_dynamic					IN	campaign.dynamic%TYPE,
	out_campaign_sid			OUT	security.security_pkg.T_SID_ID
)
AS
	v_status					campaign.status%TYPE;
	v_name						campaign.name%TYPE;
	v_act						security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app						security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
	v_table_sid					security.security_pkg.T_SID_ID := in_table_sid;
	v_filter_sid				security.security_pkg.T_SID_ID := in_filter_sid;
	v_flow_sid					security.security_pkg.T_SID_ID := in_flow_sid;
BEGIN
	IF in_audience_type = 'LF' THEN
		v_flow_sid := NULL;

	DELETE FROM campaign_region
	 WHERE campaign_sid = in_campaign_sid;
	 ELSIF in_audience_type = 'WF' THEN
		v_table_sid := NULL;
		v_filter_sid := NULL;
	  ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown campaign audience type: '||in_audience_type);
	END IF;

	IF NVL(in_campaign_sid,0) < 1 THEN
		-- security checks are in here
		security.SecurableObject_pkg.CreateSO(v_act, in_parent_sid, security.class_pkg.GetClassID('CSRSurveyCampaign'), in_name, out_campaign_sid);

		INSERT INTO campaign (campaign_sid, name, audience_type, table_sid, filter_sid, flow_sid,
			inc_regions_with_no_users, skip_overlapping_regions, survey_sid, frame_id, subject, body,
			send_after_dtm, status, sent_dtm, period_start_dtm, period_end_dtm, carry_forward_answers,
			send_to_column_sid, region_column_sid, created_by_sid, campaign_end_dtm, send_alert, dynamic)
		VALUES (out_campaign_sid, in_name, in_audience_type, v_table_sid, v_filter_sid, v_flow_sid,
			in_inc_regions_w_no_users, in_skip_overlapping_regions, in_survey_sid, in_frame_id, in_subject, in_body,
			in_send_after_dtm, 'draft', NULL, in_period_start_dtm, in_period_end_dtm, in_carry_forward_answers,
			in_send_to_column_sid, in_region_column_sid, SYS_CONTEXT('SECURITY','SID'), in_end_dtm, in_send_alert, in_dynamic);

	ELSE
		IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
		END IF;

		SELECT status, name
		  INTO v_status, v_name
		  FROM campaign
		 WHERE campaign_sid = in_campaign_sid;

		IF v_status NOT IN ('draft', 'pending') THEN
			RAISE_APPLICATION_ERROR(-20001,'Cannot update a campaign with a status of '||v_status);
		END IF;

		UPDATE campaign
		   SET name = in_name,
		       audience_type = in_audience_type,
		       table_sid = v_table_sid,
		       filter_sid = v_filter_sid,
		       flow_sid = v_flow_sid,
		       inc_regions_with_no_users = in_inc_regions_w_no_users,
		       skip_overlapping_regions = in_skip_overlapping_regions,
		       survey_sid = in_survey_sid,
		       frame_id = in_frame_id,
		       subject = in_subject,
		       body = in_body,
		       send_after_dtm = in_send_after_dtm,
			   campaign_end_dtm = in_end_dtm,
		       period_start_dtm = in_period_start_dtm,
		       period_end_dtm = in_period_end_dtm,
			   carry_forward_answers = in_carry_forward_answers,
			   send_to_column_sid = in_send_to_column_sid,
			   region_column_sid = in_region_column_sid,
			   send_alert = in_send_alert,
			   dynamic = in_dynamic
		 WHERE app_sid = security.security_pkg.GetApp
		   AND campaign_sid = in_campaign_sid;

		IF security.securableobject_pkg.GetParent(v_act, in_campaign_sid) != in_parent_sid THEN
			security.securableobject_pkg.MoveSO(v_act, in_campaign_sid, in_parent_sid);
		END IF;

		IF LOWER(v_name) != LOWER(in_name) THEN
			security.securableobject_pkg.RenameSO(v_act, in_campaign_sid, in_name);
		END IF;

		out_campaign_sid := in_campaign_sid;
	END IF;
END;

PROCEDURE SaveOpenCampaign (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_inc_regions_w_no_users	IN	campaign.inc_regions_with_no_users%TYPE,
	in_skip_overlapping_regions	IN	campaign.skip_overlapping_regions%TYPE,
	in_frame_id					IN	campaign.frame_id%TYPE,
	in_subject					IN	campaign.subject%TYPE,
	in_body						IN	campaign.body%TYPE,
	in_end_dtm					IN	campaign.campaign_end_dtm%TYPE,
	in_carry_forward_answers	IN	campaign.carry_forward_answers%TYPE,
	in_send_alert				IN	campaign.send_alert%TYPE,
	in_dynamic					IN	campaign.dynamic%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	UPDATE campaign
	   SET inc_regions_with_no_users = in_inc_regions_w_no_users,
		   skip_overlapping_regions = in_skip_overlapping_regions,
		   frame_id = in_frame_id,
		   subject = in_subject,
		   body = in_body,
		   campaign_end_dtm = in_end_dtm,
		   carry_forward_answers = in_carry_forward_answers,
		   send_alert = in_send_alert,
		   dynamic = in_dynamic
	 WHERE app_sid = security.security_pkg.GetApp
	   AND campaign_sid = in_campaign_sid;
END;

PROCEDURE SaveEmailTemplate (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_frame_id					IN	campaign.frame_id%TYPE,
	in_subject					IN	campaign.subject%TYPE,
	in_body						IN	campaign.body%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	UPDATE campaign
	   SET frame_id = in_frame_id,
		   subject = in_subject,
		   body = in_body
	 WHERE app_sid = security.security_pkg.GetApp
	   AND campaign_sid = in_campaign_sid;
END;

PROCEDURE StartSystemGeneratedCampaign (
	in_parent_sid				 IN	security.security_pkg.T_SID_ID,
	in_name						 IN	campaign.name%TYPE,
	in_survey_sid				 IN	security.security_pkg.T_SID_ID,
	in_customer_alert_type_id	 IN	campaign.customer_alert_type_id%TYPE,
	in_table_sid				 IN	security.security_pkg.T_SID_ID,
	in_filter_xml				 IN	campaign.filter_xml%TYPE := NULL,
	in_send_to_column_sid		 IN	campaign.send_to_column_sid%TYPE,
	in_region_column_sid		 IN	campaign.region_column_sid%TYPE := NULL,
	in_response_column_sid		 IN	campaign.response_column_sid%TYPE := NULL,
	in_tag_lookup_column_sid	 IN	campaign.tag_lookup_key_column_sid%TYPE := NULL,
	in_start_dtm				 IN	campaign.send_after_dtm%TYPE := NULL,
	in_end_dtm					 IN	DATE := NULL,
	out_campaign_sid			OUT	security.security_pkg.T_SID_ID
)
AS
	v_act						security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app						security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
BEGIN
	-- security checks are in here
	security.SecurableObject_pkg.CreateSO(v_act, in_parent_sid, security.class_pkg.GetClassID('CSRSurveyCampaign'), in_name, out_campaign_sid);

	INSERT INTO campaign (campaign_sid, name, audience_type, table_sid, filter_xml, survey_sid,
		   customer_alert_type_id, status, send_to_column_sid, region_column_sid, created_by_sid,
		   is_system_generated, response_column_sid, tag_lookup_key_column_sid, send_after_dtm,
		   campaign_end_dtm)
	VALUES (out_campaign_sid, in_name, 'LF', in_table_sid, in_filter_xml, in_survey_sid,
		   in_customer_alert_type_id, 'pending', in_send_to_column_sid, in_region_column_sid,
		   SYS_CONTEXT('SECURITY','SID'), 1, in_response_column_sid, in_tag_lookup_column_sid,
		   in_start_dtm, in_end_dtm);
END;

PROCEDURE UNSEC_SetCampaignStatus (
	in_campaign_sid				 IN	security.security_pkg.T_SID_ID,
	in_status					 IN	campaign.status%TYPE
)
AS
	v_status					campaign.status%TYPE;
	v_audience_type				campaign.audience_type%TYPE;
	v_resend					campaign.resend%TYPE;
BEGIN
	SELECT status, audience_type, resend
	  INTO v_status, v_audience_type, v_resend
	  FROM campaign
	 WHERE campaign_sid = in_campaign_sid;

	IF v_status = 'sent' AND in_status = 'pending' AND v_audience_type='WF' THEN
		UPDATE campaign
		   SET status = 'sending'
		 WHERE app_sid = security.security_pkg.GetApp
		   AND campaign_sid = in_campaign_sid;
	ELSIF v_status = 'sent' THEN
		RAISE_APPLICATION_ERROR(-20001,'Cannot update a campaign with a status of sent');
	ELSIF in_status = 'error' THEN
		UPDATE campaign
		   SET status = in_status
		 WHERE app_sid = security.security_pkg.GetApp
		   AND campaign_sid = in_campaign_sid;
	ELSIF v_status IN ('draft', 'pending') AND in_status = 'pending' THEN
		UPDATE campaign
		   SET status = in_status
		 WHERE app_sid = security.security_pkg.GetApp
		   AND campaign_sid = in_campaign_sid;
	ELSIF (v_status IN ('pending') AND in_status = 'sending') OR (v_status IN ('sending') AND in_status = 'emailing') THEN
		UPDATE campaign
		   SET status = in_status
		 WHERE app_sid = security.security_pkg.GetApp
		   AND campaign_sid = in_campaign_sid;
	ELSIF v_status IN ('sending', 'emailing') AND in_status = 'sent' THEN
		   IF v_resend = 1 THEN
			UPDATE campaign
			   SET status = 'sending', sent_dtm = SYSDATE, resend = 0
			 WHERE app_sid = security.security_pkg.GetApp
			   AND campaign_sid = in_campaign_sid;
		   ELSE
			UPDATE campaign
			   SET status = in_status, sent_dtm = SYSDATE
			 WHERE app_sid = security.security_pkg.GetApp
			   AND campaign_sid = in_campaign_sid;
		   END IF;
	ELSE
		RAISE_APPLICATION_ERROR(-20001,'Cannot change the status of a campaign from '||v_status||' to '||in_status);
	END IF;
END;

PROCEDURE SetCampaignStatus (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_status					IN	campaign.status%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	UNSEC_SetCampaignStatus(in_campaign_sid, in_status);
END;

PROCEDURE SetCampaignEmailStatuses
AS
BEGIN
	FOR r IN (
		SELECT campaign_sid
		  FROM campaign c
		 WHERE c.status='emailing'
		   AND NOT EXISTS (SELECT * FROM csr.alert_mail am WHERE am.app_sid = c.app_sid)
	) LOOP
		campaign_pkg.SetCampaignStatus(r.campaign_sid, 'sent');
	END LOOP;
END;

PROCEDURE GetChildRegions(
	in_campaign_sid		IN	security.security_pkg.T_SID_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_flow_sid			IN	security.security_pkg.T_SID_ID,
	out_region_cur		OUT	SYS_REFCURSOR,
	out_user_cur		OUT	SYS_REFCURSOR,
	out_reg_usr_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading regions:' || in_parent_sid);
	END IF;

	OPEN out_region_cur FOR
		SELECT sid, description, is_leaf, class_name, 0 has_manual_amends, region_selection, tag_id
		  FROM (
				SELECT NVL(lr.region_sid, r.region_sid) sid, NVL(lr.description, r.description) description,
					   rt.class_name, cr.region_selection, cr.tag_id,
						CASE
							WHEN EXISTS (SELECT * FROM csr.region child WHERE child.active = 1 AND child.parent_sid = NVL(lr.region_sid, r.region_sid))
							THEN 0 ELSE 1
						END is_leaf
				  FROM csr.v$region r
			 LEFT JOIN csr.v$region lr ON r.link_to_region_sid = lr.region_sid
			      JOIN csr.region_type rt ON NVL(lr.region_type, r.region_type) = rt.region_type
			 LEFT JOIN campaign_region cr ON NVL(lr.region_sid, r.region_sid) = cr.region_sid
				   AND cr.campaign_sid = in_campaign_sid
				 WHERE r.parent_sid = in_parent_sid
				   AND NVL(lr.active, r.active) = 1
				   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		 ORDER BY description, sid; -- ordering by sid is critical (description first as looks nicer)

	-- TODO: Doesn't include involvement types
	-- Was broken by US5953
	-- Includes all users, including trashed and hidden ones (don't use v$csr_user, js above doesn't handle it).
	OPEN out_user_cur FOR
		SELECT cu.csr_user_sid user_sid, cu.full_name name, cu.email, NVL(ut.account_enabled,0) active
		  FROM csr.csr_user cu
		  LEFT JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		  JOIN (
			SELECT DISTINCT user_sid
			  FROM csr.flow f
			  JOIN csr.flow_state_role_capability fsrc ON f.default_state_id = fsrc.flow_state_id
			  JOIN csr.region_role_member rrm ON fsrc.role_sid = rrm.role_sid
			  JOIN csr.region r ON rrm.region_sid = NVL(r.link_to_region_sid, r.region_sid)
			 WHERE f.flow_sid = in_flow_sid
			   AND fsrc.flow_capability_id = csr.csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
			   AND BITAND(fsrc.permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE
			   AND r.parent_sid = in_parent_sid
		  ) rrm ON rrm.user_sid = cu.csr_user_sid;

	OPEN out_reg_usr_cur FOR
		SELECT DISTINCT r.region_sid, rrm.user_sid
		  FROM csr.flow f
		  JOIN csr.flow_state_role_capability fsrc ON f.default_state_id = fsrc.flow_state_id
		  JOIN csr.region_role_member rrm ON fsrc.role_sid = rrm.role_sid
		  JOIN csr.region r ON rrm.region_sid = NVL(r.link_to_region_sid, r.region_sid)
		 WHERE f.flow_sid = in_flow_sid
		   AND fsrc.flow_capability_id = csr.csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
		   AND BITAND(fsrc.permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE
		   AND r.parent_sid = in_parent_sid;
END;

PROCEDURE GetRegions(
	in_campaign_sid					IN	security.security_pkg.T_SID_ID,
	in_region_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_regions						security.T_ORDERED_SID_TABLE;
BEGIN
	-- ProcessStartPoints checks for read permission on the regions
	v_regions := csr.region_pkg.ProcessStartPoints(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sids, 0);

	OPEN out_cur FOR
		SELECT sid, description, is_leaf, class_name, 0 has_manual_amends, region_selection, tag_id
		  FROM (
				SELECT r.region_sid sid, r.description, rt.class_name,
						cr.region_selection, cr.tag_id,
						CASE
							WHEN EXISTS (SELECT * FROM csr.region child WHERE child.parent_sid = r.region_sid)
							THEN 0 ELSE 1
						END is_leaf
				  FROM csr.v$region r
				  JOIN csr.region_type rt ON r.region_type = rt.region_type
				  JOIN TABLE(v_regions) rs ON rs.sid_id = r.region_sid
			      LEFT JOIN campaign_region cr ON r.region_sid = cr.region_sid
				   AND cr.campaign_sid = in_campaign_sid
				 WHERE r.active = 1
				   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		 ORDER BY description, sid; -- ordering by region_sid is critical (description first as looks nicer)
END;

PROCEDURE RemoveRegionSelections(
	in_campaign_sid		IN	security.security_pkg.T_SID_ID,
	in_region_sids		IN	security.security_pkg.T_SID_IDS
)
AS
	v_region_sids		security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	DELETE FROM campaign_region
	 WHERE campaign_sid = in_campaign_sid
	   AND region_sid IN (
		SELECT column_value
		  FROM TABLE(v_region_sids)
		);
END;

PROCEDURE SetRegionSelection(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	in_region_selection			IN	campaign_region.region_selection%TYPE,
	in_tag_id					IN	campaign_region.tag_id%TYPE
)
AS
	v_survey_sid				security.security_pkg.T_SID_ID;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	BEGIN
		INSERT INTO campaign_region (campaign_sid, region_sid, region_selection, tag_id)
		VALUES (in_campaign_sid, in_region_sid, in_region_selection, in_tag_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE campaign_region
			   SET region_selection = in_region_selection,
			       tag_id = in_tag_id
			 WHERE campaign_sid = in_campaign_sid
			   AND region_sid = in_region_sid;
	END;
END;

PROCEDURE ValidateCampaignForm (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_validation_status	OUT	NUMBER
)
AS
BEGIN
	-- If sending to an email column type (i.e. not system user), or sharing a
	-- region column between users (i.e. region_column_sid is set)
	-- then check that survey audience is "everyone"
	FOR chk IN (
		SELECT * FROM DUAL WHERE EXISTS (
			SELECT *
			  FROM campaign c
			  JOIN cms.tab_column tc ON c.send_to_column_sid = tc.column_sid AND c.app_sid = tc.app_sid
			  JOIN csr.quick_survey s ON c.survey_sid = s.survey_sid AND c.app_sid = s.app_sid
			 WHERE c.campaign_sid = in_campaign_sid
			   AND (tc.col_type NOT IN (cms.tab_pkg.CT_USER, cms.tab_pkg.CT_OWNER_USER)
			    OR c.region_column_sid IS NOT NULL)
			   AND s.audience NOT IN ('everyone')
		)
	) LOOP
		out_validation_status := NO_EVERYONE_PERMISSIONS;
		RETURN;
	END LOOP;

	out_validation_status := VALID;
END;

FUNCTION ValidateCampaignRegions (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_validation_status	OUT	NUMBER
) RETURN T_REGION_OVERLAP_TABLE
AS
	t_region_sids			T_REGION_OVERLAP_TABLE;
BEGIN
	-- This gets run even if v_skip_overlaps=1 as this method is also called by
	-- CreateRegionResponses
	t_region_sids := campaign_pkg.INTERNAL_GetCampaignRegions(in_campaign_sid);

	-- This doesn't check heirachy but at least a user won't be sent
	-- 2 of the same surveys for the same region / time period
	SELECT CASE COUNT(*) WHEN 0 THEN VALID ELSE OVERLAPPING_REGIONS END
	  INTO out_validation_status
	  FROM TABLE(t_region_sids) tr
	 WHERE tr.overlapping = 1;

	IF out_validation_status = 0 THEN
		SELECT CASE COUNT(*) WHEN 0 THEN NO_REGIONS ELSE VALID END
		  INTO out_validation_status
		  FROM TABLE(t_region_sids);
	END IF;

	RETURN t_region_sids;
END;

PROCEDURE ValidateCampaignRegions (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_validation_status	OUT	NUMBER
)
AS
	t_region_sids			T_REGION_OVERLAP_TABLE;
BEGIN
	t_region_sids := ValidateCampaignRegions(in_campaign_sid, out_validation_status);
END;

PROCEDURE INTERNAL_AddRegionResponse (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	in_response_id			IN	campaign_region_response.response_id%TYPE,
	in_region_sid			IN	campaign_region_response.region_sid%TYPE,
	in_surveys_version		IN	campaign_region_response.surveys_version%TYPE,
	in_flow_item_id			IN	campaign_region_response.flow_item_id%TYPE,
	in_response_uuid		IN	campaign_region_response.response_uuid%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO campaign_region_response (campaign_sid, response_id, region_sid, surveys_version, flow_item_id, response_uuid)
	VALUES (in_campaign_sid, in_response_id, in_region_sid, in_surveys_version, in_flow_item_id, in_response_uuid);
END;

PROCEDURE CreateRegionResponses (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_user_cur			OUT	SYS_REFCURSOR
)
AS
	v_period_start_dtm			campaign.period_start_dtm%TYPE;
	v_period_end_dtm			campaign.period_end_dtm%TYPE;
	v_survey_sid				security.security_pkg.T_SID_ID;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_aggregate_ind_group_id	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_guid						csr.quick_survey_response.guid%TYPE;
	v_response_id				csr.quick_survey_response.survey_response_id%TYPE;
	v_flow_item_id				csr.flow_item.flow_item_id%TYPE;
	v_validation_status			NUMBER;
	v_is_new_response			NUMBER;
	v_new_reponses				security.T_SID_TABLE := security.T_SID_TABLE();
	t_region_sids				T_REGION_OVERLAP_TABLE;
	t_new_region_sids			T_REGION_OVERLAP_TABLE;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	SELECT c.period_start_dtm, c.period_end_dtm, c.survey_sid, c.flow_sid, qs.aggregate_ind_group_id
	  INTO v_period_start_dtm, v_period_end_dtm, v_survey_sid, v_flow_sid, v_aggregate_ind_group_id
	  FROM campaign c
	  LEFT JOIN csr.quick_survey qs on c.survey_sid = qs.survey_sid
	 WHERE c.campaign_sid = in_campaign_sid;

	IF v_period_start_dtm IS NULL OR v_period_end_dtm IS NULL OR v_survey_sid IS NULL OR v_flow_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot roll out a campaign with null start/end date, a null survey sid or a null flow sid. Campaign sid: '||in_campaign_sid);
	END IF;

	t_region_sids := ValidateCampaignRegions(in_campaign_sid, v_validation_status);

	IF v_validation_status = NO_REGIONS THEN
		RAISE_APPLICATION_ERROR(-20001, 'Campaign has no regions. Campaign sid: '||in_campaign_sid);
	ELSIF v_validation_status = OVERLAPPING_REGIONS THEN
		RAISE_APPLICATION_ERROR(-20001, 'Campaign regions overlap with an existing campaign. Campaign sid: '||in_campaign_sid);
	ELSIF v_validation_status != VALID THEN
		RAISE_APPLICATION_ERROR(-20001, 'Error while validating campaign: '||in_campaign_sid||', error: '||v_validation_status);
	END IF;

	-- Hide responses that have been previously created but are now not in the list of regions to send to
	UPDATE csr.quick_survey_response
	   SET hidden = 1
	 WHERE qs_campaign_sid = in_campaign_sid
	   AND survey_response_id IN (
		SELECT qsr.survey_response_id
		  FROM csr.region_survey_response rsr
		  JOIN csr.quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id AND rsr.app_sid = qsr.app_sid
		 WHERE qsr.qs_campaign_sid = in_campaign_sid
		   AND rsr.region_sid NOT IN (
			SELECT region_sid FROM TABLE(t_region_sids)
		)
	);

	-- Don't create responses for regions that have been sent before by this campaign
	SELECT t_region_overlap_row(region_sid, overlapping)
	  BULK COLLECT INTO t_new_region_sids
	  FROM TABLE(t_region_sids) tr
	 WHERE tr.region_sid NOT IN (
		SELECT rsr.region_sid
		  FROM csr.region_survey_response rsr
		  JOIN csr.quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id AND rsr.app_sid = qsr.app_sid
		 WHERE qsr.qs_campaign_sid = in_campaign_sid
		   AND qsr.hidden = 0
		);

	-- Create responses where there isn't a response for the same time period already
	FOR r IN (
		SELECT region_sid
		  FROM TABLE(t_new_region_sids)
	) LOOP
		csr.quick_survey_pkg.GetOrCreateCampaignResponse(
			in_campaign_sid		=> in_campaign_sid,
			in_region_sid		=> r.region_sid,
			out_is_new_response	=> v_is_new_response,
			out_guid			=> v_guid,
			out_response_id		=> v_response_id);

		IF v_is_new_response = 1 THEN
			v_new_reponses.extend;
			v_new_reponses(v_new_reponses.COUNT) := v_response_id;
			csr.flow_pkg.AddQuickSurveyResponse(v_response_id, v_flow_sid, v_flow_item_id);
			INTERNAL_AddRegionResponse(in_campaign_sid, v_response_id, r.region_sid, 1, v_flow_item_id);
		END IF;
	END LOOP;

	-- refresh agg ind group in case we have removed previous submissions
	IF v_aggregate_ind_group_id IS NOT NULL THEN
		csr.aggregate_ind_pkg.RefreshGroup(v_aggregate_ind_group_id, v_period_start_dtm, v_period_end_dtm);
	END IF;

	-- Join to responses table and return regions
	OPEN out_region_cur FOR
		SELECT tr.region_sid, r.description region_description,
			   rsr.survey_response_id, qsr.guid response_guid,
			   qsr.survey_response_id response_id,
			   CASE WHEN nr.column_value IS NULL THEN 0 ELSE 1 END is_new_response
		  FROM TABLE(t_new_region_sids) tr
		  JOIN csr.v$region r ON tr.region_sid = r.region_sid
		  JOIN csr.region_survey_response rsr ON rsr.region_sid = tr.region_sid
		  JOIN csr.quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id AND rsr.app_sid = qsr.app_sid
		  LEFT JOIN TABLE(v_new_reponses) nr ON nr.column_value = qsr.survey_response_id
		 WHERE rsr.period_start_dtm = v_period_start_dtm
		   AND rsr.period_end_dtm = v_period_end_dtm
		   AND rsr.survey_sid = v_survey_sid
		   AND qsr.qs_campaign_sid = in_campaign_sid
		   AND qsr.hidden = 0;

	-- Join to region_members table and return users (should perhaps join to )
	OPEN out_user_cur FOR
		SELECT tr.region_sid, u.csr_user_sid user_sid, u.full_name, u.friendly_name, u.email
		  FROM TABLE(t_new_region_sids) tr
		  JOIN csr.region_role_member rrm ON rrm.region_sid = tr.region_sid
		  JOIN csr.csr_user u ON u.csr_user_sid = rrm.user_sid
		 WHERE rrm.role_sid IN (
			SELECT fsrc.role_sid
			  FROM csr.flow f
			  JOIN csr.flow_state_role_capability fsrc ON f.default_state_id = fsrc.flow_state_id
			  JOIN csr.region_role_member rrm ON fsrc.role_sid = rrm.role_sid
			  JOIN csr.region r ON rrm.region_sid = NVL(r.link_to_region_sid, r.region_sid)
			 WHERE f.flow_sid = v_flow_sid
			   AND fsrc.flow_capability_id = csr.csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
			   AND BITAND(fsrc.permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE
			);
END;

PROCEDURE MarkCampaignReadyToSend (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	-- SetCampaignStatus does security checks
	SetCampaignStatus(in_campaign_sid, 'pending');
END;

PROCEDURE GetJobsToRun (
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Called from scheduled tasks

	DELETE FROM csr.temp_campaign_sid;

	INSERT INTO csr.temp_campaign_sid (app_sid, qs_campaign_sid)
	SELECT app_sid, campaign_sid
	  FROM campaign c
	 WHERE status IN ('pending', 'sending')
	   AND (send_after_dtm IS NULL OR send_after_dtm <= SYSDATE)
	   AND NOT EXISTS(SELECT * FROM csr.trash WHERE trash_sid = c.campaign_sid);

	UPDATE campaign
	   SET status='sending'
	 WHERE campaign_sid IN (SELECT qs_campaign_sid FROM csr.temp_campaign_sid);

	OPEN out_cur FOR
		SELECT c.app_sid, c.campaign_sid, c.table_sid, c.filter_sid, c.audience_type,
				c.survey_sid, c.frame_id, c.subject, c.body, c.send_to_column_sid,
				c.region_column_sid, c.created_by_sid, so.parent_sid_id parent_sid,
				c.response_column_sid, c.tag_lookup_key_column_sid, c.is_system_generated,
				c.customer_alert_type_id, c.send_alert, c.dynamic, c.resend
		  FROM campaign c
		  JOIN csr.temp_campaign_sid t ON t.app_sid = c.app_sid AND t.qs_campaign_sid = c.campaign_sid
		  JOIN security.securable_object so ON c.campaign_sid = so.sid_id AND c.app_sid = so.application_sid_id
		 ORDER BY app_sid, created_by_sid;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
BEGIN
	RETURN csr.quick_survey_pkg.FlowItemRecordExists(in_flow_item_id);
END;

PROCEDURE GetFlowAlerts(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT x.app_sid, x.flow_state_transition_id, x.flow_item_generated_alert_id,
			   x.customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label,
			   x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,x.set_dtm,
			   x.to_user_sid, x.flow_alert_helper, x.to_user_name, x.to_full_name, x.to_email,
			   x.to_friendly_name,x.to_initiator, x.flow_item_id, x.flow_transition_alert_id,
			   p.campaign_sid, p.name, p.survey_sid, p.period_start_dtm, p.period_end_dtm,
			   wr.path survey_path, qsr.survey_response_id, x.comment_text,
			   qss.submitted_dtm submission_dtm, r.region_sid, r.description region_description
		  FROM csr.v$open_flow_item_gen_alert x
		  JOIN csr.flow_item fi ON x.flow_item_id = fi.flow_item_id AND x.app_sid = fi.app_sid
		  JOIN csr.quick_survey_response qsr ON fi.survey_response_id = qsr.survey_response_id AND fi.app_sid = qsr.app_sid
		  JOIN security.web_resource wr ON qsr.survey_sid = wr.sid_id
		  JOIN campaign p ON qsr.qs_campaign_sid = p.campaign_sid AND qsr.app_sid = p.app_sid
		  LEFT JOIN csr.region_survey_response rsr ON qsr.app_sid = rsr.app_sid AND qsr.survey_response_id = rsr.survey_response_id
		  LEFT JOIN csr.v$region r ON rsr.app_sid = r.app_sid AND rsr.region_sid = r.region_sid
		  LEFT JOIN csr.quick_survey_submission qss ON qsr.app_sid = qss.app_sid AND qsr.survey_response_id = qss.survey_response_id
		   AND qsr.last_submission_id = qss.submission_id
		 WHERE qsr.hidden = 0 -- Don't send to hidden responses
		 ORDER BY x.app_sid, x.customer_alert_type_id, x.to_user_sid, flow_item_id;-- Order matters!
END;

PROCEDURE GetStatus (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_status_cur			OUT	SYS_REFCURSOR,
	out_role_cur			OUT	SYS_REFCURSOR,
	out_status_role_cur		OUT	SYS_REFCURSOR
)
AS
	t_region_sids			T_REGION_OVERLAP_TABLE;
BEGIN
	t_region_sids := campaign_pkg.INTERNAL_GetCampaignRegions(in_campaign_sid);

	OPEN out_status_cur FOR
		SELECT r.region_sid, r.description region_description, r.parent_sid,
			   CASE WHEN fs.label IS NULL AND t.region_sid IS NOT NULL
					THEN 'Not sent' ELSE fs.label END current_state
		  FROM csr.v$region r
		  JOIN (
			SELECT DISTINCT region_sid
			  FROM csr.region
			 START WITH region_sid IN (SELECT region_sid FROM TABLE(t_region_sids))
			CONNECT BY PRIOR parent_sid = region_sid
		  ) rt ON r.region_sid = rt.region_sid
		  LEFT JOIN TABLE(t_region_sids) t ON rt.region_sid = t.region_sid
		  LEFT JOIN campaigns.campaign_region_response crr ON t.region_sid = crr.region_sid
		   AND crr.campaign_sid = in_campaign_sid
		  LEFT JOIN csr.flow_item fi ON crr.flow_item_id = fi.flow_item_id
		  LEFT JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id;

	OPEN out_role_cur FOR
		SELECT r.role_sid, r.name, fr.is_emailed
		  FROM csr.role r
		  JOIN (
			SELECT fsrc.role_sid,
					MAX(
						CASE WHEN fs.flow_state_id = f.default_state_id
							THEN CASE WHEN BITAND(fsrc.permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE THEN 1 ELSE 0 END
						ELSE 0
					END) is_emailed
			  FROM csr.flow_state_role_capability fsrc
			  JOIN csr.flow_state fs ON fsrc.flow_state_id = fs.flow_state_id
			  JOIN csr.flow f ON fs.flow_sid = f.flow_sid
			  JOIN campaign c ON f.flow_sid = c.flow_sid
			 WHERE c.campaign_sid = in_campaign_sid
			 GROUP BY fsrc.role_sid
		  ) fr ON r.role_sid = fr.role_sid;

	OPEN out_status_role_cur FOR
		SELECT rrm.region_sid, rrm.role_sid, cu.full_name, cu.email
		  FROM csr.region_role_member rrm
		  JOIN TABLE(t_region_sids) t ON rrm.region_sid = t.region_sid
		  JOIN csr.csr_user cu ON rrm.user_sid = cu.csr_user_sid
		  JOIN (
			SELECT DISTINCT fsr.role_sid
			  FROM csr.flow_state_role fsr
			  JOIN csr.flow_state fs ON fsr.flow_state_id = fs.flow_state_id
			  JOIN campaign c ON fs.flow_sid = c.flow_sid
			 WHERE c.campaign_sid = in_campaign_sid
		  ) r ON rrm.role_sid = r.role_sid
		 ORDER BY rrm.region_sid, rrm.role_sid, cu.full_name;
END;

PROCEDURE UpdateCampaignEndDate (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	in_end_dtm				IN	campaign.campaign_end_dtm%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_campaign_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write access denied on campaign with sid: '||in_campaign_sid);
	END IF;

	UPDATE campaign
	   SET campaign_end_dtm = in_end_dtm
	 WHERE campaign_sid = in_campaign_sid;
END;

FUNCTION CheckResponseClosed (
	in_survey_response_id			IN	csr.quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER
AS
	v_end_dtm				DATE;
	v_result 				NUMBER(1);
BEGIN
	SELECT c.campaign_end_dtm
	  INTO v_end_dtm
	  FROM csr.quick_survey_response qsr
 LEFT JOIN campaign c ON c.campaign_sid = qsr.qs_campaign_sid
	 WHERE qsr.survey_response_id = in_survey_response_id;

	IF v_end_dtm IS NULL OR v_end_dtm > SYSDATE THEN
		v_result := 0;
	ELSE
		v_result := 1;
	END IF;

	RETURN v_result;
END;

FUNCTION CheckResponseClosedByGuid (
	in_guid							IN	csr.quick_survey_response.guid%TYPE
) RETURN NUMBER
AS
	v_survey_response_id	csr.quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_survey_response_id := csr.quick_survey_pkg.CheckGuidAccess(in_guid);
	RETURN CheckResponseClosed(v_survey_response_id);
END;

PROCEDURE ApplyDynamicCampaign (
	in_region_sid					IN	csr.region.region_sid%TYPE
)
AS
BEGIN
	FOR c IN (
		SELECT DISTINCT c.campaign_sid, c.status
		  FROM
			(SELECT region_sid
			   FROM csr.region
			  START WITH region_sid = in_region_sid
			CONNECT BY PRIOR parent_sid = NVL(link_to_region_sid, region_sid)
			) r
		  JOIN campaign_region cr ON cr.region_sid = r.region_sid
		  JOIN campaign c ON c.campaign_sid = cr.campaign_sid
		 WHERE NOT EXISTS(SELECT * FROM csr.trash WHERE trash_sid = c.campaign_sid) --this probably needs to be done in a better way
		   AND c.status in ('sending', 'sent', 'emailing')
		   AND (c.campaign_end_dtm IS NULL OR c.campaign_end_dtm >= SYSDATE)
		   AND c.dynamic = 1)
	LOOP
		IF c.status = 'sent' THEN
			UNSEC_SetCampaignStatus(c.campaign_sid, 'pending');
		ELSE
			--if the campaign is being sent, mark it for resend instead of changing status right away
			UPDATE campaign SET resend = 1 WHERE campaign_sid = c.campaign_sid AND resend = 0;
		END IF;
	END LOOP;
END;

PROCEDURE ApplyCampaignScoresToProperty(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to publish scores from campagin survey response to property (where the score_type 'applies_to_regions').
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update company scores in other circumstances.
	v_region_sid				security.security_pkg.T_SID_ID;
	v_score_type_id				csr.score_type.score_type_id%TYPE;
	v_score_threshold_id		csr.quick_survey_submission.score_threshold_id%TYPE;
	v_overall_score				NUMBER;
	v_as_of_date				DATE;
	v_period_end_date			DATE;
BEGIN
	BEGIN
		SELECT rsr.region_sid, st.score_type_id, qss.overall_score, qss.score_threshold_id, rsr.PERIOD_END_DTM 
		  INTO v_region_sid, v_score_type_id, v_overall_score, v_score_threshold_id, v_period_end_date
		  FROM csr.flow_item fi
		  JOIN csr.quick_survey_response qsr ON fi.survey_response_id = qsr.survey_response_id
		  JOIN csr.quick_survey qs ON qsr.survey_sid = qs.survey_sid
		  JOIN csr.score_type st ON qs.score_type_id = st.score_type_id
		  JOIN csr.region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  JOIN csr.region rg ON rsr.region_sid = rg.region_sid
		  JOIN csr.quick_survey_submission qss ON qsr.last_submission_id = qss.submission_id
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND st.APPLIES_TO_REGIONS = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				aspen2.error_pkg.LogError('Warning. Campaign helper did not copy survey score to region when transitioning to state: ' || in_to_state_id || ' for flow item id:'||in_flow_item_id);
				RETURN;
	END;
	
	csr.quick_survey_pkg.UNSEC_PublishRegionScore(
		in_region_sid		=> v_region_sid,
		in_score_type_id	=> v_score_type_id,
		in_score			=> v_overall_score,
		in_threshold_id		=> v_score_threshold_id,
		in_comment_text		=> 'Publish score from campaign workflow item ' || in_flow_item_id
	);

END;

PROCEDURE ApplyCampaignScoresToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to publish scores from campagin survey responses to supplier (where the score_type 'applies_to_supplier'.
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update company scores in other circumstances.
	v_company_sid				security.security_pkg.T_SID_ID;
	v_score_type_id				csr.score_type.score_type_id%TYPE;
	v_score_threshold_id		csr.quick_survey_submission.score_threshold_id%TYPE;
	v_overall_score				NUMBER;
	v_as_of_date				DATE;
	v_period_end_date			DATE;
	v_submission_id				csr.quick_survey_submission.submission_id%TYPE;
BEGIN
	BEGIN
		SELECT s.company_sid, st.score_type_id, qss.overall_score, qss.score_threshold_id, rsr.PERIOD_END_DTM, qss.submission_id
		  INTO v_company_sid, v_score_type_id, v_overall_score, v_score_threshold_id, v_period_end_date, v_submission_id
		  FROM csr.flow_item fi
		  JOIN csr.quick_survey_response qsr ON fi.survey_response_id = qsr.survey_response_id
		  JOIN csr.quick_survey qs ON qsr.survey_sid = qs.survey_sid
		  JOIN csr.score_type st ON qs.score_type_id = st.score_type_id
		  JOIN csr.region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  JOIN csr.supplier s ON rsr.region_sid = s.region_sid
		  JOIN csr.quick_survey_submission qss ON qsr.last_submission_id = qss.submission_id
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND st.APPLIES_TO_SUPPLIER = 1;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				aspen2.error_pkg.LogError('Warning. Campaign helper did not copy survey score to supplier when transitioning to state: ' || in_to_state_id || ' for flow item id:'||in_flow_item_id);
				RETURN;
	END;
	
	
	csr.supplier_pkg.UNSEC_UpdateSupplierScore(
		in_supplier_sid			=> v_company_sid,
		in_score_type_id		=> v_score_type_id,
		in_score				=> v_overall_score,
		in_threshold_id			=> v_score_threshold_id,
		in_as_of_date			=> SYSDATE,
		in_comment_text			=> 'Copy score from campaign workflow item ' || in_flow_item_id,
		in_valid_until_dtm		=> v_period_end_date,
		in_score_source_type	=> csr.csr_data_pkg.SCORE_SOURCE_TYPE_QS,
		in_score_source_id		=> v_submission_id
	);
END;

FUNCTION GetResponseCapability(
	in_flow_item		csr.flow_item.flow_item_id%TYPE
) RETURN NUMBER
AS
BEGIN
	RETURN csr.quick_survey_pkg.GetResponseCapability(in_flow_item);
END;

FUNCTION CheckResponseCapability(
	in_flow_item		csr.flow_item.flow_item_id%TYPE,
	in_expected_perm	NUMBER
) RETURN NUMBER
AS
BEGIN
	RETURN csr.quick_survey_pkg.CheckResponseCapability(in_flow_item, in_expected_perm);
END;

FUNCTION INTERNAL_GetCampaignRegions (
	in_campaign_sid		IN	security.security_pkg.T_SID_ID
) RETURN T_REGION_OVERLAP_TABLE
AS
	v_inc_regions_with_no_users	campaign.inc_regions_with_no_users%TYPE;
	v_skip_overlapping_regions	campaign.skip_overlapping_regions%TYPE;
	v_period_start_dtm			campaign.period_start_dtm%TYPE;
	v_period_end_dtm			campaign.period_end_dtm%TYPE;
	v_flow_sid					security.security_pkg.T_SID_ID;
	v_survey_sid				security.security_pkg.T_SID_ID;
	t_region_sids				T_REGION_OVERLAP_TABLE;
	t_region_no_user_sids		T_REGION_OVERLAP_TABLE;
BEGIN
	SELECT flow_sid, inc_regions_with_no_users, skip_overlapping_regions,
		   survey_sid, period_start_dtm, period_end_dtm
	  INTO v_flow_sid, v_inc_regions_with_no_users, v_skip_overlapping_regions,
		   v_survey_sid, v_period_start_dtm, v_period_end_dtm
	  FROM campaign
	 WHERE campaign_sid = in_campaign_sid;

	-- Get all regions in campaign together
	SELECT t_region_overlap_row(region_sid, overlaps)
	  BULK COLLECT INTO t_region_sids
	  FROM (
		WITH co AS (
			SELECT cr.region_sid
			  FROM campaign c
			  JOIN campaign_region cr ON cr.campaign_sid = c.campaign_sid
			   AND c.period_start_dtm < v_period_end_dtm
			   AND c.period_end_dtm > v_period_start_dtm
			 WHERE c.campaign_sid != in_campaign_sid
			   AND c.survey_sid = v_survey_sid
			   AND NOT EXISTS(SELECT * FROM csr.trash WHERE trash_sid = c.campaign_sid)
		)
		-- "just this region" ticked with optional tag
		SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, DECODE(co.region_sid, NULL, 0, 1) overlaps
		  FROM campaign_region cr
		  JOIN csr.region r ON cr.region_sid = r.region_sid
	 LEFT JOIN co ON co.region_sid = NVL(r.link_to_region_sid, r.region_sid)
		 WHERE cr.campaign_sid = in_campaign_sid
		   AND cr.region_selection = csr.csr_data_pkg.DELEG_PLAN_SEL_M_REGION
		   AND (cr.tag_id IS NULL OR EXISTS (SELECT 1 FROM csr.region_tag rt WHERE rt.region_sid = cr.region_sid AND rt.tag_id = cr.tag_id))
		 UNION
		-- region's leaf nodes with optional tag
		SELECT r.region_sid, r.overlaps
		   FROM campaign_region cr
		   JOIN (
			SELECT connect_by_root rx.region_sid root_region_sid, NVL(rx.link_to_region_sid, rx.region_sid) region_sid, DECODE(co.region_sid, NULL, 0, 1) overlaps
			  FROM csr.region rx
		 LEFT JOIN co ON co.region_sid = NVL(rx.link_to_region_sid, rx.region_sid)
			 WHERE connect_by_isleaf = 1
			 START WITH rx.active = 1 AND rx.region_sid IN (select cr.region_sid FROM campaign_region cr where cr.region_selection = csr.csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT AND cr.campaign_sid = in_campaign_sid)
			CONNECT BY rx.active = 1 AND PRIOR rx.app_sid = rx.app_sid AND PRIOR NVL(rx.link_to_region_sid, rx.region_sid) = rx.parent_sid
		   ) r ON r.root_region_sid = cr.region_sid AND (cr.tag_id IS NULL OR EXISTS (SELECT 1 FROM csr.region_tag rt WHERE rt.region_sid = r.region_sid AND rt.tag_id = cr.tag_id))
		 WHERE cr.campaign_sid = in_campaign_sid
		   AND cr.region_selection = csr.csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT
		  UNION
		-- region's lower property nodes with optional tag
		SELECT r.region_sid, r.overlaps
		   FROM campaign_region cr
		   JOIN (
			SELECT connect_by_root rx.region_sid root_region_sid, NVL(rx.link_to_region_sid, rx.region_sid) region_sid, DECODE(co.region_sid, NULL, 0, 1) overlaps
			  FROM csr.region rx
		 LEFT JOIN co ON co.region_sid = NVL(rx.link_to_region_sid, rx.region_sid)
			 WHERE region_type = csr.csr_data_pkg.REGION_TYPE_PROPERTY
			 START WITH rx.active = 1 AND rx.region_sid IN (select cr.region_sid from campaign_region cr where cr.region_selection = csr.csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT AND cr.campaign_sid = in_campaign_sid)
			CONNECT BY rx.active = 1 AND PRIOR rx.app_sid = rx.app_sid AND PRIOR NVL(rx.link_to_region_sid, rx.region_sid) = rx.parent_sid
		   ) r ON r.root_region_sid = cr.region_sid AND (cr.tag_id IS NULL OR EXISTS (SELECT 1 FROM csr.region_tag rt WHERE rt.region_sid = r.region_sid AND rt.tag_id = cr.tag_id))
		 WHERE cr.campaign_sid = in_campaign_sid
		   AND cr.region_selection = csr.csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT
		)
	;
	
	IF v_inc_regions_with_no_users = 0 THEN
		SELECT t_region_overlap_row(region_sid, overlapping)
		  BULK COLLECT INTO t_region_no_user_sids
		  FROM TABLE(t_region_sids)
		 WHERE region_sid IN (
			SELECT rrm.region_sid
			  FROM csr.flow f
			  JOIN csr.flow_state_role_capability fsrc ON f.default_state_id = fsrc.flow_state_id
			  JOIN csr.region_role_member rrm ON fsrc.role_sid = rrm.role_sid
			  JOIN csr.region r ON rrm.region_sid = NVL(r.link_to_region_sid, r.region_sid)
			 WHERE f.flow_sid = v_flow_sid
			   AND fsrc.flow_capability_id = csr.csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
			   AND BITAND(fsrc.permission_set, security.security_pkg.PERMISSION_WRITE) = security.security_pkg.PERMISSION_WRITE -- no point sending a survey to a read-only user
		);
		
		RETURN t_region_no_user_sids;
	END IF;
	
	RETURN t_region_sids;
END;

-- offers backwards compatibility to surveys2 
PROCEDURE INTERNAL_GetCampaignRegions (
	in_campaign_sid		IN	security.security_pkg.T_SID_ID
)
AS
	t_region_sids			campaigns.T_REGION_OVERLAP_TABLE;
BEGIN
	t_region_sids := campaigns.campaign_pkg.INTERNAL_GetCampaignRegions(in_campaign_sid);
	
	DELETE FROM csr.temp_region_sid;

	INSERT INTO csr.temp_region_sid (region_sid)
	SELECT region_sid
	  FROM TABLE(t_region_sids);
END;

FUNCTION GetCampaignDetails(
	in_campaign_sid		IN	security.security_pkg.T_SID_ID
) RETURN T_CAMPAIGN_TABLE
AS
	v_campaign_tab	T_CAMPAIGN_TABLE;
BEGIN
	SELECT 	campaigns.T_CAMPAIGN_ROW(
			app_sid => c.app_sid,
			qs_campaign_sid => c.campaign_sid, -- keep for backwards compatibility
			campaign_sid => c.campaign_sid,
			name => c.name,
			table_sid => c.table_sid,
			filter_sid => c.filter_sid,
			survey_sid => c.survey_sid,
			frame_id => c.frame_id,
			subject => c.subject,
			body => c.body,
			send_after_dtm => c.send_after_dtm,
			status => c.status,
			sent_dtm => c.sent_dtm,
			period_start_dtm => c.period_start_dtm,
			period_end_dtm => c.period_end_dtm,
			audience_type => c.audience_type,
			flow_sid => c.flow_sid,
			inc_regions_with_no_users => c.inc_regions_with_no_users,
			skip_overlapping_regions => c.skip_overlapping_regions,
			carry_forward_answers => c.carry_forward_answers,
			send_to_column_sid => c.send_to_column_sid,
			region_column_sid => c.region_column_sid,
			created_by_sid => c.created_by_sid,
			filter_xml => c.filter_xml,
			response_column_sid => c.response_column_sid,
			tag_lookup_key_column_sid => c.tag_lookup_key_column_sid,
			is_system_generated => c.is_system_generated,
			customer_alert_type_id => c.customer_alert_type_id,
			campaign_end_dtm => c.campaign_end_dtm,
			send_alert => c.send_alert,
			dynamic => c.dynamic,
			resend => c.resend)
	  BULK COLLECT INTO v_campaign_tab
	  FROM campaign c
	 WHERE campaign_sid = in_campaign_sid;
	 
	RETURN v_campaign_tab;
END;

FUNCTION GetOverlappingCampaignSids(
	in_campaign_sid		IN	security.security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE
AS
	v_campaign_sids	security.security_pkg.T_SID_IDS;
BEGIN
	SELECT s.campaign_sid
	  BULK COLLECT INTO v_campaign_sids
	  FROM campaign s
	  JOIN campaign c ON s.survey_sid = c.survey_sid AND s.period_start_dtm = c.period_start_dtm AND s.period_end_dtm = c.period_end_dtm
	 WHERE c.campaign_sid = in_campaign_sid
	   AND NOT EXISTS (SELECT * FROM csr.trash WHERE trash_sid = s.campaign_sid);

	RETURN security.security_pkg.SidArrayToTable(v_campaign_sids);
END;

FUNCTION GetOvlpCampaignSidsForPeriod(
	in_campaign_sid		IN	security.security_pkg.T_SID_ID,
	in_period_start_dtm	IN	campaign.period_start_dtm%TYPE,
	in_period_end_dtm	IN	campaign.period_end_dtm%TYPE
) RETURN security.T_SID_TABLE
AS
	v_campaign_sids 		security.security_pkg.T_SID_IDS;
BEGIN
	SELECT campaign_sid
	  BULK COLLECT INTO v_campaign_sids
	  FROM campaign
	 WHERE campaign_sid != in_campaign_sid
	   AND period_start_dtm < in_period_end_dtm
	   AND period_end_dtm > in_period_start_dtm
	   AND NOT EXISTS (SELECT * FROM csr.trash WHERE trash_sid = campaign_sid);

	RETURN security.security_pkg.SidArrayToTable(v_campaign_sids);
END;

FUNCTION GetCampaignDetailsForSids(
	in_campaign_sids	IN	security.security_pkg.T_SID_IDS
) RETURN T_CAMPAIGN_TABLE
AS
	v_campaign_sid_table	security.T_SID_TABLE;
	v_campaign_tab 			T_CAMPAIGN_TABLE;
BEGIN
	v_campaign_sid_table := security.security_pkg.SidArrayToTable(in_campaign_sids);

	SELECT 	campaigns.T_CAMPAIGN_ROW(
			app_sid => c.app_sid,
			qs_campaign_sid => c.campaign_sid, -- keep for backwards compatibility
			campaign_sid => c.campaign_sid,
			name => c.name,
			table_sid => c.table_sid,
			filter_sid => c.filter_sid,
			survey_sid => c.survey_sid,
			frame_id => c.frame_id,
			subject => c.subject,
			body => c.body,
			send_after_dtm => c.send_after_dtm,
			status => c.status,
			sent_dtm => c.sent_dtm,
			period_start_dtm => c.period_start_dtm,
			period_end_dtm => c.period_end_dtm,
			audience_type => c.audience_type,
			flow_sid => c.flow_sid,
			inc_regions_with_no_users => c.inc_regions_with_no_users,
			skip_overlapping_regions => c.skip_overlapping_regions,
			carry_forward_answers => c.carry_forward_answers,
			send_to_column_sid => c.send_to_column_sid,
			region_column_sid => c.region_column_sid,
			created_by_sid => c.created_by_sid,
			filter_xml => c.filter_xml,
			response_column_sid => c.response_column_sid,
			tag_lookup_key_column_sid => c.tag_lookup_key_column_sid,
			is_system_generated => c.is_system_generated,
			customer_alert_type_id => c.customer_alert_type_id,
			campaign_end_dtm => c.campaign_end_dtm,
			send_alert => c.send_alert,
			dynamic => c.dynamic,
			resend => c.resend)
	  BULK COLLECT INTO v_campaign_tab
	  FROM campaign c
	  JOIN TABLE(v_campaign_sid_table) s ON s.column_value = c.campaign_sid
	 WHERE NOT EXISTS (SELECT * FROM csr.trash WHERE trash_sid = c.campaign_sid);

	RETURN v_campaign_tab;
END;

FUNCTION GetAllCampaignSids
RETURN security.T_SID_TABLE
AS
	v_campaign_sids security.T_SID_TABLE;
BEGIN
	SELECT c.campaign_sid
	  BULK COLLECT INTO v_campaign_sids
	  FROM campaign c
	 WHERE NOT EXISTS (SELECT * FROM csr.trash WHERE trash_sid = c.campaign_sid);

	RETURN v_campaign_sids;
END;

FUNCTION GetAllCampaignDetails 
RETURN T_CAMPAIGN_TABLE
AS
	v_campaign_sids		security.security_pkg.T_SID_IDS;
BEGIN
	SELECT campaign_sid
	  BULK COLLECT INTO v_campaign_sids
	  FROM campaign c
	 WHERE app_sid = security.security_pkg.GetApp;

	RETURN GetCampaignDetailsForSids(v_campaign_sids);
END;

PROCEDURE RemoveCustomerAlertType(
	in_customer_alert_type_id	IN	campaign.customer_alert_type_id%TYPE
)
AS
BEGIN
	UPDATE campaign
	   SET customer_alert_type_id = NULL
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
END;

PROCEDURE DeleteForApp(
	in_app_sid		IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM campaign_region_response
	 WHERE app_sid = in_app_sid;
	
	DELETE FROM campaign_region
	 WHERE app_sid = in_app_sid;
	 
	DELETE FROM campaign
	 WHERE app_sid = in_app_sid;
END;

FUNCTION GetCampaignSid(
	in_name			IN	campaign.name%TYPE
) RETURN campaign.campaign_sid%TYPE
AS
	v_campaign_sid		campaign.campaign_sid%TYPE;
BEGIN
	SELECT MAX(campaign_sid)
	  INTO v_campaign_sid
	  FROM campaign
	 WHERE lower(name) = lower(in_name)
	   AND csr.trash_pkg.IsInTrashHierarchical(SYS_CONTEXT('SECURITY','ACT'), campaign_sid) = 0;

	RETURN v_campaign_sid;
END;

PROCEDURE GetAllCampaigns(
	out_campaign_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_campaign_cur FOR
		SELECT campaign_sid, name, table_sid, filter_sid, survey_sid, frame_id,
			   subject, body, send_after_dtm, status, sent_dtm, period_start_dtm,
			   period_end_dtm, audience_type, flow_sid, inc_regions_with_no_users,
			   skip_overlapping_regions, carry_forward_answers, send_to_column_sid,
			   region_column_sid, created_by_sid, filter_xml, response_column_sid,
			   tag_lookup_key_column_sid, is_system_generated, customer_alert_type_id,
			   campaign_end_dtm, send_alert, dynamic, resend
		  FROM campaigns.campaign;
END;

PROCEDURE RestartFailedCampaign(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE campaign
	   SET status = 'pending'
	 WHERE status = 'error'
	   and campaign_sid = in_campaign_sid;
END;

PROCEDURE GetCampaignResponses_Unsec (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_responses_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_responses_cur FOR
		SELECT ccr.app_sid, ccr.campaign_sid, ccr.region_sid, ccr.response_id, ccr.flow_item_id,
			wr.path survey_path, ccr.response_uuid
		  FROM campaign_region_response ccr
		  JOIN campaign c ON c.campaign_sid = ccr.campaign_sid
		  JOIN security.web_resource wr ON wr.sid_id = c.survey_sid
		 WHERE ccr.campaign_sid = in_campaign_sid;
END;

PROCEDURE GetCampaignNames (
	out_campaigns_cur		OUT SYS_REFCURSOR
)
AS
	v_act					security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_app					security.security_pkg.T_ACT_ID := security.security_pkg.GetApp;
	v_campaigns_sid			security.security_pkg.T_SID_ID := security.securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Campaigns');
	v_desc_with_read_perm 	security.T_SO_DESCENDANTS_TABLE;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(v_act, v_campaigns_sid, security.security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'List contents access denied on App/Campaigns');
	END IF;

	v_desc_with_read_perm := security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act, v_campaigns_sid, security.security_pkg.PERMISSION_READ);

	OPEN out_campaigns_cur FOR
		SELECT c.campaign_sid, c.name
		  FROM campaign c
		  JOIN TABLE(v_desc_with_read_perm) t ON c.campaign_sid = t.sid_id;
END;

FUNCTION HasPermissionOnResponse(
	in_response_uuid		campaign_region_response.response_uuid%TYPE,
	in_capability_id		NUMBER,
	in_expected_permission	security.security_pkg.T_PERMISSION
) RETURN NUMBER
AS
	v_flow_item_id			campaign_region_response.flow_item_id%TYPE;
	v_campaign_end_dtm		campaign.campaign_end_dtm%TYPE;
	v_permission_set		security.security_pkg.T_PERMISSION;
BEGIN
	SELECT c.campaign_end_dtm, crr.flow_item_id
	  INTO v_campaign_end_dtm, v_flow_item_id
	  FROM campaign_region_response crr
	  JOIN campaign c ON crr.campaign_sid = c.campaign_sid
	 WHERE crr.app_sid = security.security_pkg.GetApp
	   AND LOWER(crr.response_uuid) = LOWER(in_response_uuid);

	IF in_expected_permission = security.security_pkg.PERMISSION_WRITE AND v_campaign_end_dtm < SYSDATE THEN
		RETURN 0;
	END IF;

	v_permission_set := csr.flow_pkg.GetItemCapabilityPermission(
		in_flow_item_id => v_flow_item_id,
		in_capability_id => in_capability_id 
	);

	IF BITAND(v_permission_set, in_expected_permission) = in_expected_permission THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE GetRegionResponses(
	in_region_sid				IN	campaign_region_response.region_sid%TYPE,
	out_cur						OUT	sys_refcursor
)
AS
	v_flow_item_ids				security.T_SID_TABLE;
BEGIN
	v_flow_item_ids :=
		csr.flow_pkg.GetPermissibleRegionItems(
			in_capability_id	=> 1001,
			in_region_sid		=> in_region_sid
		);

	OPEN out_cur FOR
		SELECT c.survey_sid, fs.label as state, fsl.set_dtm set_on_dtm, crr.response_id
		  FROM campaign_region_response crr
		  JOIN campaign c ON c.campaign_sid = crr.campaign_sid
		  JOIN csr.flow_item fi ON crr.flow_item_id = fi.flow_item_id
		  JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
	 LEFT JOIN csr.flow_state_log fsl ON fi.last_flow_state_log_id = fsl.flow_state_log_id
	 	  JOIN TABLE(v_flow_item_ids) t ON fi.flow_item_id = t.column_value
		 WHERE crr.region_sid = in_region_sid;
END;

PROCEDURE GetUnregisteredResources(
	out_cur			OUT	sys_refcursor
)
AS
	v_flow_item_ids				security.T_SID_TABLE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'GetUnregisteredResponses can only run by BuiltIn Admin');
	END IF;

	OPEN out_cur FOR
		SELECT response_uuid, app_sid
		  FROM campaign_region_response 
		 WHERE registered_in_acg_dtm IS NULL
		   AND response_uuid IS NOT NULL
		 ORDER BY app_sid;
END;

PROCEDURE MarkResourceAsRegistered(
	in_response_uuid		IN	campaign_region_response.response_uuid%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'MarkResponseAsRegistered can only run by BuiltIn Admin');
	END IF;

	UPDATE campaign_region_response
	   SET registered_in_acg_dtm = SYSDATE
	 WHERE LOWER(response_uuid) = LOWER(in_response_uuid);

	COMMIT;
END;

END campaign_pkg;
/