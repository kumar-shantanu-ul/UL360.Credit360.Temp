CREATE OR REPLACE PACKAGE CSR.supplier_pkg AS

TYPE T_DATE_TABLE IS TABLE OF DATE INDEX BY PLS_INTEGER;

PROCEDURE ChainCompanyUserCreated(
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE UpdateTasksForCompany(
	in_company_sid			IN security_pkg.T_SID_ID
);

PROCEDURE SyncCompanyTypeRoles(
	in_company_sid				IN security_pkg.T_SID_ID,
	in_use_cascade_role_changed	IN NUMBER DEFAULT 0,
	in_supplier_company_sid		IN security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE UNSEC_RemoveFollowerRoles(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE UNSEC_SyncFollowerRoles(
	in_purchaser_company_type	IN	chain.company_type.company_type_id%TYPE,
	in_supplier_company_type	IN	chain.company_type.company_type_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE UNSEC_SyncCompanyFollowerRoles(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE AddCompanyUser(
	in_company_sid      IN  security_pkg.T_SID_ID,
	in_user_sid         IN  security_pkg.T_SID_ID
);

PROCEDURE RemoveUserFromCompany(
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE CreateSupplierRole(
	in_role_name					IN 	role.name%TYPE,
	out_role_sid					OUT	role.role_sid%TYPE
);

FUNCTION GetRegionSid(
	in_company_sid				security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

FUNCTION GetCompanySid(
	in_region_sid				security_pkg.T_SID_ID,
	in_swallow_not_found		NUMBER DEFAULT 0
) RETURN security_pkg.T_SID_ID;

PROCEDURE AddCompanyFromRegion(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_company_type_id	IN	chain.company_type.company_type_id%TYPE,
	in_sector_id		IN  chain.company.sector_id%TYPE DEFAULT NULL,
	in_lookup_keys		IN	chain.chain_pkg.T_STRINGS DEFAULT chain.chain_pkg.EMPTY_VALUES, --reference labels
	in_values			IN	chain.chain_pkg.T_STRINGS DEFAULT chain.chain_pkg.EMPTY_VALUES, --reference labels
	out_company_sid		OUT	security_pkg.T_SID_ID
);

FUNCTION GetChainDocumentLibrary
RETURN security_pkg.T_SID_ID;

FUNCTION GetPermissibleDocumentFolders(
	in_doc_library_sid				IN  security_pkg.T_SID_ID
)
RETURN security.T_SID_TABLE;

FUNCTION CheckDocumentPermissions(
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

FUNCTION GetDocumentLibraryFolder (
	in_company_sid					IN  security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID;


PROCEDURE AddMissingCompanyDocFolders;

PROCEDURE AddCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
);

PROCEDURE SetLatLong(
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_latitude			IN	region.geo_latitude%TYPE,
	in_longitude		IN	region.geo_longitude%TYPE
);

PROCEDURE DeleteCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
);

PROCEDURE VirtualDeleteCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
);

PROCEDURE InviteCreated(
	in_invitation_id			IN	chain.invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE QuestionnaireAdded(
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE
);

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE DeactivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ReactivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateUser(
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ApproveUser(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship(
	in_owner_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship(
	in_owner_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

-- marks a delegation as suitable for use with
-- the supply chain system
PROCEDURE MarkDelegationAsTemplate(
	in_delegation_sid	IN	security_pkg.T_SID_ID
);


PROCEDURE GetSheets(
	in_company_sid			IN 	security_pkg.T_SID_ID,
	in_tpl_delegation_sid	IN 	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE DeleteQuestionnaires(
	in_company_sid			IN 	security_pkg.T_SID_ID
);

PROCEDURE GetMyCompanies(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyProfile(
	in_company_sid	security_pkg.T_SID_ID,
	out_cur	OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyProfile(
	out_cur	OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE UploadLogo(
	in_company_sid	IN	security_pkg.T_SID_ID,
	in_cache_key	IN	aspen2.filecache.cache_key%type,
	out_logo_sid	OUT	security_pkg.T_SID_ID
);

PROCEDURE GetInviteLandingDetails(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE UnmakeChainSurvey(
	in_quick_survey_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE MakeChainSurvey(
	in_quick_survey_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE SearchQuestionnairesByType(
	in_questionnaire_type_id	IN	NUMBER,
	in_phrase					IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyScores(
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyScoreLog(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierExtrasData(
	in_company_sids				IN  security_pkg.T_SID_IDS,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_SetSupplierScoreThold(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	supplier_score_log.score_threshold_id%TYPE,
	in_comment_text				IN	supplier_score_log.comment_text%TYPE,
	in_set_dtm					IN  supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL, 
	in_force_set_current		IN	NUMBER DEFAULT 1
);

PROCEDURE SetSupplierScoreThreshold(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	supplier_score_log.score_threshold_id%TYPE,
	in_comment_text				IN	supplier_score_log.comment_text%TYPE
);

PROCEDURE UNSEC_UpdateSupplierScore(
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_score					IN	quick_survey_submission.overall_score%TYPE,
	in_threshold_id				IN	quick_survey_submission.score_threshold_id%TYPE,
	in_as_of_date				IN	supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_comment_text				IN	supplier_score_log.comment_text%TYPE DEFAULT NULL,
	in_valid_until_dtm			IN  supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL,
	in_score_source_type		IN	supplier_score_log.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN	supplier_score_log.score_source_id%TYPE DEFAULT NULL,
	in_propagate_scores			IN	NUMBER DEFAULT 1,
	in_force_set_current		IN	NUMBER DEFAULT 1
);

FUNCTION GetScoreTypeIdByKey(
	in_key					IN csr.score_type.lookup_key%TYPE 
) RETURN csr.score_type.score_type_id%TYPE;

FUNCTION GetScoreThreshIdByKey(
	in_score_type_id		IN csr.score_threshold.score_type_id%TYPE,
	in_key					IN csr.score_threshold.lookup_key%TYPE 
) RETURN csr.score_threshold.score_threshold_id%TYPE;

PROCEDURE QuestionnaireShareStatusChange(
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid	IN	security_pkg.T_SID_ID,
	in_qnr_owner_company_sid	IN	security_pkg.T_SID_ID,
	in_status					IN	chain.chain_pkg.T_SHARE_STATUS
);

PROCEDURE QuestionnaireStatusChange(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE,
	in_status_id				IN	chain.chain_pkg.T_QUESTIONNAIRE_STATUS
);

PROCEDURE FilterSuppliersByScore(
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterQuestionnaireStatuses (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE AddSupplierIssue(
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_label					IN	issue.label%TYPE,
	in_description				IN	issue_log.message%TYPE,
	in_assigned_to_user_sid		IN	issue.assigned_to_user_sid%TYPE								DEFAULT NULL,
	in_role_sid					IN	security_pkg.T_SID_ID										DEFAULT NULL,
	in_due_dtm					IN	issue.due_dtm%TYPE											DEFAULT NULL,
	in_qs_expr_nc_action_id		IN	non_compliance_expr_action.qs_expr_non_compl_action_id%TYPE	DEFAULT NULL,
	in_is_urgent				IN	NUMBER														DEFAULT NULL,
	in_is_critical				IN	issue.is_critical%TYPE										DEFAULT 0,
	out_issue_id				OUT	issue.issue_id%TYPE
);

PROCEDURE UNSEC_SetTags(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_ids				IN	security_pkg.T_SID_IDS,
	in_tag_group_id 		IN	tag_group.tag_group_id%TYPE DEFAULT NULL
);

PROCEDURE UNSEC_SetTagsInsertOnly(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetTags(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_tag_ids					IN	security_pkg.T_SID_IDS,
	in_tag_group_id 			IN	tag_group.tag_group_id%TYPE DEFAULT NULL
);

FUNCTION GetTags(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE;

PROCEDURE GetTags(
	in_company_sid				IN	security_pkg.T_SID_ID,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION UNSEC_GetTagsText(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN  tag_group.tag_group_id%TYPE
)RETURN VARCHAR2;

PROCEDURE FilterCompaniesByTags(
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN  chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
);

/* 
Appears to be unused.
Comment out for now in case it turns up in an undocumented helper proc.
PROCEDURE GetMonthlyScoreIndData(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);
*/

PROCEDURE GetScoreIndValData(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SynchScoreInds(
	in_parent_ind_sid			IN	security_pkg.T_SID_ID,
	in_helper_proc				IN	VARCHAR2 DEFAULT 'csr.supplier_pkg.GetScoreIndValData'
);

PROCEDURE GetSupplierFlowAggregates(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT SYS_REFCURSOR
);

-- Currently only called by cvs\clients\marksandspencer\db\chain_setup_body. To be removed.
PROCEDURE CreateSupplierFlowIndicators(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_start_date				IN	DATE,
	in_end_date					IN	DATE
);

-- Primarily used for Funds (Properties).
PROCEDURE GetSuppliers(
	in_supplier_sid		IN		supplier.company_sid%TYPE	DEFAULT NULL,	-- NULL = Get All
	out_cur				OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE NukeChain;

FUNCTION GetRegSidsFromCompSids (
	in_company_sids				IN	security_pkg.T_SID_IDS
) RETURN security_pkg.T_SID_IDS;

PROCEDURE GetRegSidsFromCompSids (
	in_company_sids				IN	security_pkg.T_SID_IDS, 
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

END supplier_pkg;
/
