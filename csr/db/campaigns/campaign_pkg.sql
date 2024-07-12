CREATE OR REPLACE PACKAGE campaigns.campaign_pkg AS

VALID					CONSTANT	NUMBER(10) := 0;
OVERLAPPING_REGIONS		CONSTANT	NUMBER(10) := 1;
NO_REGIONS				CONSTANT	NUMBER(10) := 2;
NO_EVERYONE_PERMISSIONS	CONSTANT	NUMBER(10) := 3;

PROCEDURE CreateObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID,
	in_class_id					IN  security.security_pkg.T_CLASS_ID,
	in_name						IN  security.security_pkg.T_SO_NAME,
	in_parent_sid_id			IN  security.security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID,
	in_new_name					IN  security.security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID
); 

PROCEDURE MoveObject(
	in_act_id					IN  security.security_pkg.T_ACT_ID,
	in_sid_id					IN  security.security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN  security.security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN	security.security_pkg.T_SID_ID
); 

PROCEDURE TrashCampaign(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
);

PROCEDURE GetCampaign (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetRecipientViewXml (
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetCampaignList (
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetCampaigns (
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetCampaignPeriodsBySids(
	in_campaign_sids			IN	security.security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
);

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
);

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
);

PROCEDURE SaveEmailTemplate(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_frame_id					IN	campaign.frame_id%TYPE,
	in_subject					IN	campaign.subject%TYPE,
	in_body						IN	campaign.body%TYPE
);

PROCEDURE StartSystemGeneratedCampaign(
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	in_name						IN	campaign.name%TYPE,
	in_survey_sid				IN	security.security_pkg.T_SID_ID,
	in_customer_alert_type_id	IN	campaign.customer_alert_type_id%TYPE,
	in_table_sid				IN	security.security_pkg.T_SID_ID,
	in_filter_xml				IN	campaign.filter_xml%TYPE := NULL,
	in_send_to_column_sid		IN	campaign.send_to_column_sid%TYPE,
	in_region_column_sid		IN	campaign.region_column_sid%TYPE := NULL,
	in_response_column_sid		IN	campaign.response_column_sid%TYPE := NULL,
	in_tag_lookup_column_sid	IN	campaign.tag_lookup_key_column_sid%TYPE := NULL,
	in_start_dtm				IN	campaign.send_after_dtm%TYPE := NULL,
	in_end_dtm					IN	DATE := NULL,
	out_campaign_sid			OUT	security.security_pkg.T_SID_ID
);

PROCEDURE SetCampaignStatus(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_status					IN	campaign.status%TYPE
);

PROCEDURE SetCampaignEmailStatuses;

PROCEDURE GetChildRegions(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_parent_sid				IN	security.security_pkg.T_SID_ID,
	in_flow_sid					IN	security.security_pkg.T_SID_ID,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_user_cur				OUT	SYS_REFCURSOR,
	out_reg_usr_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetRegions(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_region_sids				IN	security.security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE RemoveRegionSelections(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_region_sids				IN	security.security_pkg.T_SID_IDS
);

PROCEDURE SetRegionSelection(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_region_sid				IN	security.security_pkg.T_SID_ID,
	in_region_selection			IN	campaign_region.region_selection%TYPE,
	in_tag_id					IN	campaign_region.tag_id%TYPE
);

PROCEDURE ValidateCampaignForm(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_validation_status		OUT	NUMBER
);

PROCEDURE ValidateCampaignRegions(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_validation_status		OUT	NUMBER
);

PROCEDURE CreateRegionResponses(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_user_cur				OUT	SYS_REFCURSOR
);

PROCEDURE MarkCampaignReadyToSend(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
);

PROCEDURE GetJobsToRun(
	out_cur						OUT	SYS_REFCURSOR
);

FUNCTION FlowItemRecordExists(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetStatus(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	out_status_cur				OUT	SYS_REFCURSOR,
	out_role_cur				OUT	SYS_REFCURSOR,
	out_status_role_cur			OUT	SYS_REFCURSOR
);

PROCEDURE UpdateCampaignEndDate(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_end_dtm					IN	campaign.campaign_end_dtm%TYPE
);

FUNCTION CheckResponseClosed(
	in_survey_response_id		IN	csr.quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER;

FUNCTION CheckResponseClosedByGuid(
	in_guid						IN	csr.quick_survey_response.guid%TYPE
) RETURN NUMBER;

PROCEDURE ApplyDynamicCampaign(
	in_region_sid				IN	csr.region.region_sid%TYPE
);

PROCEDURE ApplyCampaignScoresToProperty(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

PROCEDURE ApplyCampaignScoresToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr.flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
);

FUNCTION GetResponseCapability(
	in_flow_item				IN	csr.flow_item.flow_item_id%TYPE
) RETURN NUMBER;

FUNCTION CheckResponseCapability(
	in_flow_item				IN	csr.flow_item.flow_item_id%TYPE,
	in_expected_perm	NUMBER
) RETURN NUMBER;

FUNCTION INTERNAL_GetCampaignRegions (
	in_campaign_sid		IN	security.security_pkg.T_SID_ID
) RETURN T_REGION_OVERLAP_TABLE;

PROCEDURE INTERNAL_GetCampaignRegions (
	in_campaign_sid		IN	security.security_pkg.T_SID_ID
);

FUNCTION GetCampaignDetails(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
) RETURN T_CAMPAIGN_TABLE;


FUNCTION GetOverlappingCampaignSids(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE;

FUNCTION GetOvlpCampaignSidsForPeriod(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID,
	in_period_start_dtm			IN	campaign.period_start_dtm%TYPE,
	in_period_end_dtm			IN	campaign.period_end_dtm%TYPE
) RETURN security.T_SID_TABLE;

FUNCTION GetCampaignDetailsForSids(
	in_campaign_sids			IN	security.security_pkg.T_SID_IDS
) RETURN T_CAMPAIGN_TABLE;

FUNCTION GetAllCampaignDetails 
RETURN T_CAMPAIGN_TABLE;

PROCEDURE RemoveCustomerAlertType(
	in_customer_alert_type_id	IN	campaign.customer_alert_type_id%TYPE
);

PROCEDURE DeleteForApp(
	in_app_sid					IN	security.security_pkg.T_SID_ID
);

FUNCTION GetCampaignSid(
	in_name						IN	campaign.name%TYPE
) RETURN campaign.campaign_sid%TYPE;

PROCEDURE GetAllCampaigns(
	out_campaign_cur			OUT	SYS_REFCURSOR
);

FUNCTION GetAllCampaignSids
RETURN security.T_SID_TABLE;

PROCEDURE RestartFailedCampaign(
	in_campaign_sid				IN	security.security_pkg.T_SID_ID
);

FUNCTION ValidateCampaignRegions (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_validation_status	OUT	NUMBER
) RETURN T_REGION_OVERLAP_TABLE;

PROCEDURE INTERNAL_AddRegionResponse (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	in_response_id			IN	campaign_region_response.response_id%TYPE,
	in_region_sid			IN	campaign_region_response.region_sid%TYPE,
	in_surveys_version		IN	campaign_region_response.surveys_version%TYPE,
	in_flow_item_id			IN	campaign_region_response.flow_item_id%TYPE,
	in_response_uuid		IN	campaign_region_response.response_uuid%TYPE DEFAULT NULL
);

PROCEDURE GetCampaignResponses_Unsec (
	in_campaign_sid			IN	security.security_pkg.T_SID_ID,
	out_responses_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetCampaignNames (
	out_campaigns_cur		OUT SYS_REFCURSOR
);

FUNCTION HasPermissionOnResponse(
	in_response_uuid		campaign_region_response.response_uuid%TYPE,
	in_capability_id		NUMBER,
	in_expected_permission	security.security_pkg.T_PERMISSION
) RETURN NUMBER;

PROCEDURE GetRegionResponses(
	in_region_sid			IN	campaign_region_response.region_sid%TYPE,
	out_cur					OUT	sys_refcursor
);

PROCEDURE GetUnregisteredResources(
	out_cur			OUT	sys_refcursor
);

PROCEDURE MarkResourceAsRegistered(
	in_response_uuid		IN	campaign_region_response.response_uuid%TYPE
);

END campaign_pkg;
/