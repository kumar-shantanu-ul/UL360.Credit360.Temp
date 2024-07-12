CREATE OR REPLACE PACKAGE CSR.quick_survey_pkg AS

MY_SURVEYS_SHOW_ALL			CONSTANT NUMBER(1) := 0;
MY_SURVEYS_SHOW_UNSUBMITTED	CONSTANT NUMBER(1) := 1;
MY_SURVEYS_SHOW_SUBMITTED	CONSTANT NUMBER(1) := 2;

-- Securable object callbacks
/**
 * CreateObject
 *
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 *
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 *
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 *
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

FUNCTION CheckGuidAccess(
	in_guid			IN	quick_survey_response.guid%TYPE,
	in_is_editable	IN	NUMBER DEFAULT 0
)
RETURN quick_survey_response.survey_response_id%TYPE;

FUNCTION GetResponseAccess(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER;

PROCEDURE CreateSurvey(
	in_name					IN  security_pkg.T_SO_NAME,
	in_label				IN  quick_survey_version.label%TYPE,
	in_audience				IN  quick_survey.audience%TYPE,
	in_group_key			IN	quick_survey.group_key%TYPE,
	in_question_xml			IN  quick_survey_version.question_xml%TYPE,
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_score_type_id		IN	quick_survey.score_type_id%TYPE,
	in_survey_type_id		IN	quick_survey_type.quick_survey_type_id%TYPE DEFAULT NULL,
	in_from_question_library IN quick_survey.from_question_library%TYPE DEFAULT 0,
	in_lookup_key			IN	quick_survey.lookup_key%TYPE DEFAULT NULL,
	out_survey_sid          OUT security_pkg.T_SID_ID
);

PROCEDURE PublishSurvey (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_update_responses_from	IN	quick_survey_version.survey_version%TYPE,
	out_publish_result			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ImportSurvey(
    in_xml					IN	quick_survey_version.question_xml%TYPE,
	in_name					IN  security_pkg.T_SO_NAME,
	in_label				IN  quick_survey_version.label%TYPE,
	in_audience				IN  quick_survey.audience%TYPE DEFAULT 'everyone',
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_lookup_key			IN	quick_survey.lookup_key%TYPE DEFAULT NULL,
	out_survey_sid          OUT security.security_pkg.T_SID_ID
);

PROCEDURE OverwriteSurvey(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_xml				IN	quick_survey_version.question_xml%TYPE
);

-- Promoted to this level so that it can be used within this package in SQL statements
FUNCTION StripIDs(
	in_doc			IN XMLType
) RETURN XMLType;

PROCEDURE CopySurvey(
	in_copy_survey_sid		IN  security_pkg.T_SID_ID,
	in_new_parent_sid		IN  security_pkg.T_SID_ID,
	in_name					IN  security_pkg.T_SO_NAME,
	in_label				IN  quick_survey_version.label%TYPE,
	out_survey_sid          OUT security_pkg.T_SID_ID
);

PROCEDURE TrashSurvey(
	in_survey_sid					IN security_pkg.T_SID_ID
);

/**
 * RestoreFromTrash
 *
 * @param in_object_sids			The objects being restored
 */
PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
);

PROCEDURE AmendSurvey(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_name				IN  security_pkg.T_SO_NAME,
	in_label			IN  quick_survey_version.label%TYPE,
	in_audience			IN  quick_survey.audience%TYPE,
	in_group_key		IN	quick_survey.group_key%TYPE,
	in_question_xml		IN  quick_survey_version.question_xml%TYPE,
	in_score_type_id	IN	quick_survey.score_type_id%TYPE,
	in_survey_type_id	IN	quick_survey_type.quick_survey_type_id%TYPE,
	in_lookup_key		IN	quick_survey.lookup_key%TYPE
);


PROCEDURE SetLookupKey(
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	in_lookup_key		IN	quick_survey_question.lookup_key%TYPE
);

PROCEDURE RaiseNonCompliance(
	in_survey_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_quick_survey_expr_action_id	IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	out_issue_ids_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestion(
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_options_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCheckboxes(
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomQuestionTypes (
	in_custom_question_type_id	IN	qs_custom_question_type.custom_question_type_id%TYPE := NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddTempQuestion(
	in_question_id				IN  tempor_question.question_id%TYPE,
	in_question_version			IN  tempor_question.question_version%TYPE,	
	in_parent_id				IN  tempor_question.parent_id%TYPE,
	in_parent_version			IN  tempor_question.parent_version%TYPE,
	in_label					IN  tempor_question.label%TYPE,
	in_question_type			IN  tempor_question.question_type%TYPE,
	in_score					IN  tempor_question.score%TYPE,
	in_max_score				IN  tempor_question.max_score%TYPE,
	in_upload_score				IN  tempor_question.upload_score%TYPE,
	in_lookup_key				IN  tempor_question.lookup_key%TYPE,
	in_invert_score				IN  tempor_question.invert_score%TYPE,
	in_custom_question_type_id	IN  tempor_question.custom_question_type_id%TYPE,
	in_weight					IN  tempor_question.weight%TYPE,
	in_dont_normalise_score		IN	tempor_question.dont_normalise_score%TYPE,
	in_has_score_expression		IN	tempor_question.has_score_expression%TYPE,
	in_has_max_score_expr		IN	tempor_question.has_max_score_expr%TYPE,
	in_remember_answer			IN	tempor_question.remember_answer%TYPE,
	in_count_question			IN	tempor_question.count_question%TYPE,
	in_action					IN	tempor_question.action%TYPE,
	in_question_xml				IN	tempor_question.question_xml%TYPE
);

PROCEDURE AddTempQuestionOption(
	in_question_id				IN  temp_question_option.question_id%TYPE,
	in_question_version			IN  temp_question_option.question_version%TYPE,
	in_question_option_id		IN  temp_question_option.question_option_id%TYPE,
	in_label					IN  temp_question_option.label%TYPE,
	in_score					IN  temp_question_option.score%TYPE,
	in_has_override				IN  temp_question_option.has_override%TYPE,
	in_score_override			IN  temp_question_option.score_override%TYPE,
	in_hidden					IN  temp_question_option.hidden%TYPE,
	in_color					IN  temp_question_option.color%TYPE,
	in_lookup_key				IN  temp_question_option.lookup_key%TYPE,
	in_option_action			IN  temp_question_option.option_action%TYPE,
	in_non_compliance_popup		IN  temp_question_option.non_compliance_popup%TYPE,
	in_non_comp_default_id		IN  temp_question_option.non_comp_default_id%TYPE,
	in_non_compliance_type_id	IN  temp_question_option.non_compliance_type_id%TYPE,
	in_non_compliance_label		IN  temp_question_option.non_compliance_label%TYPE,
	in_non_compliance_detail	IN  temp_question_option.non_compliance_detail%TYPE,
	in_non_comp_root_cause		IN  temp_question_option.non_comp_root_cause%TYPE,
	in_non_comp_suggested_action IN  temp_question_option.non_comp_suggested_action%TYPE,
	in_question_option_xml		IN	temp_question_option.question_option_xml%TYPE
);

PROCEDURE AddTempQstnOptionNCTag(
	in_question_id				IN	temp_question_option_nc_tag.question_id%TYPE,
	in_question_version			IN	temp_question_option_nc_tag.question_version%TYPE,
	in_question_option_id		IN	temp_question_option_nc_tag.question_option_id%TYPE,
	in_tag_ids					IN	security_pkg.T_SID_IDS --not sids but will do
);

PROCEDURE AddTempQstnOptionShowQ(
	in_question_id				IN	temp_question_option_show_q.question_id%TYPE,
	in_question_version			IN	temp_question_option_show_q.question_version%TYPE,
	in_question_option_id		IN	temp_question_option_show_q.question_option_id%TYPE,
	in_show_question_ids		IN	security_pkg.T_SID_IDS,
	in_show_question_vers		IN	security_pkg.T_SID_IDS
);

PROCEDURE SetQuestionIndMappings(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_question_ids 		IN	security_pkg.T_SID_IDS,
	in_ind_sids 			IN 	security_pkg.T_SID_IDS,
	out_changed_measures	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetQuestionMeasureMappings(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_question_ids 		IN	security_pkg.T_SID_IDS,
	in_measure_sids			IN 	security_pkg.T_SID_IDS,
	out_changed_measures	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetQuestionTags(
	in_question_id					IN  quick_survey_question.question_id%TYPE,
	in_tag_ids 						IN	security_pkg.T_SID_IDS
);

PROCEDURE SetResponseQuestionXml(
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	in_question_xml_override		IN  quick_survey_response.question_xml_override%TYPE
);

PROCEDURE GetResponseQuestionXml (
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	out_xml							OUT	quick_survey_response.question_xml_override%TYPE
);

PROCEDURE GetResponseFilterQuestionIds (
	in_survey_sid				IN	csr.quick_survey.survey_sid%TYPE,
	in_survey_response_id		IN 	csr.quick_survey_answer.survey_response_id%TYPE,
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurveys(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurveys(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_filter			IN	VARCHAR2,
	in_audience			IN  quick_survey.audience%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurvey(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_version				IN	quick_survey_version.survey_version%TYPE,
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE DEFAULT NULL,
	out_cur             	OUT security_pkg.T_OUTPUT_CUR,
	out_ind_mappings_cur    OUT security_pkg.T_OUTPUT_CUR,
	out_measures_cur    	OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionID
RETURN quick_survey_question.question_id%TYPE;

FUNCTION GetQuestionOptionID
RETURN qs_question_option.question_option_id%TYPE;

FUNCTION GetResponseIdFromGUID(
	in_guid							IN	quick_survey_response.guid%TYPE
) RETURN quick_survey_response.survey_response_id%TYPE;

FUNCTION GetGUIDFromResponseId(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE
) RETURN quick_survey_response.guid%TYPE;

FUNCTION GetGUIDFromUserSidSurveySid(
	in_user_sid 					IN	quick_survey_response.user_sid%TYPE,
	in_survey_sid 					IN	quick_survey_response.survey_sid%TYPE
) RETURN quick_survey_response.guid%TYPE;

FUNCTION GetSurveyVersion(
	in_survey_sid					IN	security_pkg.T_SID_ID
) RETURN quick_survey_version.survey_version%TYPE;

PROCEDURE GetSurveyVersionFromGUID(
	in_guid							IN	quick_survey_response.guid%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE,
	out_survey_sid					OUT	security_pkg.T_SID_ID,
	out_survey_response_id			OUT	quick_survey_response.survey_response_id%TYPE,
	out_survey_version				OUT	quick_survey_version.survey_version%TYPE
);

PROCEDURE GetSurveyVersionFromResponseId(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE,
	out_survey_sid					OUT	security_pkg.T_SID_ID,
	out_survey_version				OUT	quick_survey_version.survey_version%TYPE
);

FUNCTION GetSupplierSid(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetSupplierComponentIds(
	in_guid							IN	quick_survey_response.guid%TYPE,
	out_supplier_sid				OUT	security_pkg.T_SID_ID,
	out_component_id				OUT	supplier_survey_response.component_id%TYPE
);

/**
 * NewResponse
 *
 * @param in_act_id				Access token
 * @param in_survey_sid			.
 * @param in_user_name			.
 * @param out_response_id		.
 */
PROCEDURE NewResponse(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_survey_version				IN	quick_survey_version.survey_version%TYPE,
	in_user_name					IN	QUICK_SURVEY_response.user_name%TYPE,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
);

PROCEDURE NewChainResponse(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID DEFAULT NULL, -- if null then pulls from context
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
);

PROCEDURE GetOrCreateChainResponse(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID DEFAULT NULL, -- if null then pulls from context
	in_component_id					IN  NUMBER,
	out_is_new_response				OUT NUMBER,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
);

PROCEDURE GetOrCreateCampaignResponse(
	in_campaign_sid					IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID := NULL,
	out_is_new_response				OUT NUMBER,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
);

PROCEDURE GetSupplierSid(
	in_guid							IN	quick_survey_response.guid%TYPE,
	out_supplier_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE CopyResponse (
	in_from_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_from_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_to_response_id			IN	quick_survey_response.survey_response_id%TYPE
);

FUNCTION TryGetQuestionOption(
	in_from_question_id			IN	quick_survey_question.question_id%TYPE,
	in_from_question_option_id	IN	qs_question_option.question_option_id%TYPE,
	in_to_question_id			IN	quick_survey_question.question_id%TYPE,
	in_from_survey_version		IN 	NUMBER
) RETURN NUMBER;

PROCEDURE GetAnswerNonCompliances(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	quick_survey_question.question_id%TYPE,
	out_nc_cur             	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAnswerLog(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	quick_survey_question.question_id%TYPE,
	out_cur             	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetAnswerForResponseGuid(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_question_id				IN	quick_survey_answer.question_id%TYPE,
	in_answer					IN	quick_survey_answer.answer%TYPE DEFAULT NULL,
	in_note						IN	quick_survey_answer.note%TYPE DEFAULT NULL,
	in_question_option_id		IN	quick_survey_answer.question_option_id%TYPE DEFAULT NULL,
	in_val_number				IN	quick_survey_answer.val_number%TYPE DEFAULT NULL,
	in_measure_conversion_id	IN	quick_survey_answer.measure_conversion_id%TYPE DEFAULT NULL,
	in_region_sid				IN	quick_survey_answer.region_sid%TYPE DEFAULT NULL,
	in_html_display				IN	quick_survey_answer.html_display%TYPE DEFAULT NULL,
	in_score					IN	quick_survey_answer.score%TYPE DEFAULT NULL,
	in_max_score				IN	quick_survey_answer.max_score%TYPE DEFAULT NULL,
	in_version_stamp			IN	quick_survey_answer.version_stamp%TYPE DEFAULT -1,
	in_log_item					IN	quick_survey_answer.log_item%TYPE DEFAULT NULL
);

PROCEDURE EmptyAnswers(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_question_ids				IN	security.security_pkg.T_SID_IDS
);

PROCEDURE UNSEC_EmptyAnswers(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids				IN	security.security_pkg.T_SID_IDS
);

PROCEDURE GetResponseFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	out_cur             	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseFile(
	in_sha1			IN	qs_response_file.sha1%TYPE,
	in_filename		IN	qs_response_file.filename%TYPE,
	in_mime_type	IN	qs_response_file.mime_type%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseFiles(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddResponseFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_cache_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE RemoveResponseFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_remove_sha1s			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_remove_filenames		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_remove_mimetypes		IN	security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetAnswerFiles(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_question_id				IN	qs_answer_file.question_id%TYPE,
	in_new_cache_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_new_captions				IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_sha1s			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_filenames		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_mimetypes		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_caption_updates	IN	security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE AddAnswerFile(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_filename				IN	qs_answer_file.filename%TYPE,
	in_mime_type			IN	qs_answer_file.mime_type%TYPE,
	in_data					IN	qs_response_file.data%TYPE,
	in_caption				IN	qs_answer_file.caption%TYPE,
	in_uploaded_dtm			IN	qs_response_file.uploaded_dtm%TYPE
);

PROCEDURE AddAnswerFile(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_filename				IN	qs_answer_file.filename%TYPE,
	in_mime_type			IN	qs_answer_file.mime_type%TYPE,
	in_data					IN	qs_response_file.data%TYPE,
	in_caption				IN	qs_answer_file.caption%TYPE,
	in_uploaded_dtm			IN	qs_response_file.uploaded_dtm%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddAnswerFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_captions				IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE RemoveAnswerFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_remove_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE UpdateFileCaptions(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_file_ids				IN	security_pkg.T_SID_IDS,
	in_captions				IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE GetAnswerFile(
	in_qs_answer_file_id	IN	qs_answer_file.qs_answer_file_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStopQuestionIds(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponse(
	in_response_id	    	IN	QUICK_SURVEY_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseByGuid(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseAnswers(
	in_response_id	    	IN	QUICK_SURVEY_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseAnswers(
	in_response_id	    	IN	QUICK_SURVEY_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids			IN	security_pkg.T_SID_IDS,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseAnswersByGuid(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids			IN	security_pkg.T_SID_IDS,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseValues(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_answers			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResponseValuesByGuid(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_answers			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE Submit(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_geo_latitude				IN	quick_survey_submission.geo_latitude%TYPE DEFAULT NULL,
	in_geo_longitude			IN	quick_survey_submission.geo_longitude%TYPE DEFAULT NULL,
	in_geo_altitude 			IN	quick_survey_submission.geo_altitude%TYPE DEFAULT NULL,
	in_geo_h_accuracy			IN	quick_survey_submission.geo_h_accuracy%TYPE DEFAULT NULL,
	in_geo_v_accuracy			IN	quick_survey_submission.geo_v_accuracy%TYPE DEFAULT NULL,
	out_submission_id			OUT quick_survey_submission.submission_id%TYPE
);

PROCEDURE Submit(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_geo_latitude				IN	quick_survey_submission.geo_latitude%TYPE DEFAULT NULL,
	in_geo_longitude			IN	quick_survey_submission.geo_longitude%TYPE DEFAULT NULL,
	in_geo_altitude 			IN	quick_survey_submission.geo_altitude%TYPE DEFAULT NULL,
	in_geo_h_accuracy			IN	quick_survey_submission.geo_h_accuracy%TYPE DEFAULT NULL,
	in_geo_v_accuracy			IN	quick_survey_submission.geo_v_accuracy%TYPE DEFAULT NULL,
	out_submission_id			OUT quick_survey_submission.submission_id%TYPE
);

PROCEDURE GetQuestionTree(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResultsForResponseIds(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_response_ids				IN	security_pkg.T_SID_IDS,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResultsForResponseGuid(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_guid						IN	quick_survey_response.guid%TYPE,
	out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListResponses(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
    out_responses				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListResponsesComments(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
	out_comments				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ListResponsesUnansweredQuest(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
	out_unanswered_questions	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurveyScoreThresholds(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurveyResponsesUsers(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Prefix search on quick_survey.label and group_key
 *
 * @param in_filter		Prefix to search label for
 * @param in_group_key	Prefix to search group key for
 * @param out_cur		Output rowset of the form survey_sid, label
 */
PROCEDURE FilterSurveys(
	in_filter			IN	VARCHAR2,
	in_audience			IN	quick_survey.audience%TYPE,
	in_group_key		IN	VARCHAR2,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE INTERNAL_XmlUpdated(
	in_survey_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE GetSurveyTreeWithDepth(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_fetch_depth		IN  NUMBER,
	in_show_inactive 	IN 	NUMBER,
	in_group_key 		IN  VARCHAR2 DEFAULT NULL,
	in_audience			IN	VARCHAR2 DEFAULT NULL,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurveyTreeTextFiltered(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_show_inactive 	IN 	NUMBER,
	in_group_key 		IN  VARCHAR2 DEFAULT NULL,
	in_audience			IN	VARCHAR2 DEFAULT NULL,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSurveyTreeWithSelect(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_select_sid		IN	security_pkg.T_SID_ID,
	in_show_inactive 	IN 	NUMBER,
	in_group_key 		IN  VARCHAR2 DEFAULT NULL,
	in_audience			IN	VARCHAR2 DEFAULT NULL,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllSurveyQuestions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeWithDepth(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeWithSelect(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_select_sid		IN	security_pkg.T_SID_ID,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeTextFiltered(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextFiltered(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetListTextSurveys(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetExpressions(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	out_expr					OUT security_pkg.T_OUTPUT_CUR,
	out_non_compl_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_non_compl_role_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_msg_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_show_q_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_mand_q_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_show_p_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_issue_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_issue_cust_fields_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_issue_cust_opts_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateExpr(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_expr							IN	quick_survey_expr.expr%TYPE,
	in_question_id					IN	quick_survey_expr.question_id%TYPE,
	in_question_option_id			IN	quick_survey_expr.question_option_id%TYPE,
	out_expr_id						OUT	quick_survey_expr.expr_id%TYPE
);

PROCEDURE DeleteExpr(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE
);


PROCEDURE UpdateExpr(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_expr							IN	quick_survey_expr.expr%TYPE,
	in_question_id					IN	quick_survey_expr.question_id%TYPE,
	in_question_option_id			IN	quick_survey_expr.question_option_id%TYPE
);

PROCEDURE DeleteActionsNotInList (
	in_expr_id				IN	quick_survey_expr.expr_id%TYPE,
	in_actions_to_keep		IN	security_pkg.T_SID_IDS
);

PROCEDURE UNSEC_CreateExprNonComplAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_title						IN	qs_expr_non_compl_action.title%TYPE,
	in_due_dtm_abs					IN	qs_expr_non_compl_action.due_dtm_abs%TYPE,
	in_due_dtm_relative				IN	qs_expr_non_compl_action.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	qs_expr_non_compl_action.due_dtm_relative_unit%TYPE,
	in_assign_to_role_sid			IN	security_pkg.T_SID_ID,
	in_involve_role_sids			IN	security_pkg.T_SID_IDS,
	in_detail						IN	qs_expr_non_compl_action.detail%TYPE,
	in_send_email_on_creation		IN	qs_expr_non_compl_action.send_email_on_creation%TYPE,
	in_non_comp_default_id			IN  qs_expr_non_compl_action.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN  qs_expr_non_compl_action.non_compliance_type_id%TYPE DEFAULT NULL,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
);

PROCEDURE UNSEC_UpdateExprNonComplAction(
	in_qs_expr_action_id	IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_title						IN	qs_expr_non_compl_action.title%TYPE,
	in_due_dtm_abs					IN	qs_expr_non_compl_action.due_dtm_abs%TYPE,
	in_due_dtm_relative				IN	qs_expr_non_compl_action.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	qs_expr_non_compl_action.due_dtm_relative_unit%TYPE,
	in_assign_to_role_sid			IN	security_pkg.T_SID_ID,
	in_involve_role_sids			IN	security_pkg.T_SID_IDS,
	in_detail						IN	qs_expr_non_compl_action.detail%TYPE,
	in_send_email_on_creation		IN	qs_expr_non_compl_action.send_email_on_creation%TYPE,
	in_non_comp_default_id			IN  qs_expr_non_compl_action.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN  qs_expr_non_compl_action.non_compliance_type_id%TYPE DEFAULT NULL
);

PROCEDURE UNSEC_CreateExprMsgAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_msg							IN	qs_expr_msg_action.msg%TYPE,
	in_css_class					IN	qs_expr_msg_action.css_class%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
);

PROCEDURE UNSEC_UpdateExprMsgAction(
	in_qs_expr_action_id	IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_msg					IN	qs_expr_msg_action.msg%TYPE,
	in_css_class			IN	qs_expr_msg_action.css_class%TYPE
);

PROCEDURE UNSEC_CreateExprShowQAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
);

PROCEDURE UNSEC_UpdateExprShowQAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE
);

PROCEDURE UNSEC_CreateExprMandQAction (
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
);

PROCEDURE UNSEC_UpdateExprMandQAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE
);

PROCEDURE UNSEC_CreateExprShowPAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
);

PROCEDURE UNSEC_UpdateExprShowPAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE
);

PROCEDURE UNSEC_CreateExprIssueAction (
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE,
	in_label						IN	issue_template.label%TYPE,
	in_description					IN	issue_template.description%TYPE,
	in_assign_to_user_sid			IN	issue_template.assign_to_user_sid%TYPE,
	in_is_urgent					IN	issue_template.is_urgent%TYPE,
	in_is_critical					IN	issue_template.is_critical%TYPE,
	in_due_dtm						IN	issue_template.due_dtm%TYPE,
	in_due_dtm_relative				IN	issue_template.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	issue_template.due_dtm_relative_unit%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
);

PROCEDURE UNSEC_UpdateExprIssueAction (
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE,
	in_label						IN	issue_template.label%TYPE,
	in_description					IN	issue_template.description%TYPE,
	in_assign_to_user_sid			IN	issue_template.assign_to_user_sid%TYPE,
	in_is_urgent					IN	issue_template.is_urgent%TYPE,
	in_is_critical					IN	issue_template.is_critical%TYPE,
	in_due_dtm						IN	issue_template.due_dtm%TYPE,
	in_due_dtm_relative				IN	issue_template.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	issue_template.due_dtm_relative_unit%TYPE
);

PROCEDURE UNSEC_SetIssueActionCustFld (
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_issue_custom_field_id		IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_string_value					IN	issue_template_custom_field.string_value%TYPE,
	in_date_value					IN	issue_template_custom_field.date_value%TYPE,
	in_option_ids					IN	security_pkg.T_SID_IDS
);

PROCEDURE AddIssue(
	in_guid				IN	quick_survey_response.guid%TYPE,
	in_question_id 		IN  quick_survey_question.question_id%TYPE,
	in_label			IN	issue.label%TYPE,
	in_description		IN	issue_log.message%TYPE,
	in_due_dtm			IN	issue.due_dtm%TYPE,
	in_source_url		IN	issue.source_url%TYPE,
	in_is_urgent		IN	NUMBER,
	in_is_critical		IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id		OUT issue.issue_id%TYPE
);

PROCEDURE SetPostIt(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_postit_id			IN	postit.postit_id%TYPE,
	out_postit_id			OUT postit.postit_id%TYPE
);

PROCEDURE GetGeneralFilterConditionTypes (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CountSurveyResponses(
	in_survey_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetSurveyResponseIds (
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_compound_filter_id	IN  chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid			IN  security_pkg.T_SID_ID,
	out_results				OUT security.T_SID_TABLE
);

PROCEDURE GetRawResults(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid			IN	security_pkg.T_SID_ID,
	out_responses			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterResponseIds (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_sids				IN  security.T_SID_TABLE,
	out_sids			OUT security.T_SID_TABLE
);

/* filter helper_pkg proc */
PROCEDURE FilterCompanySids (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_parallel			IN	NUMBER,
	in_max_group_by		IN  NUMBER,
	in_sids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids			OUT chain.T_FILTERED_OBJECT_TABLE
);

/* filter helper_pkg proc */
PROCEDURE CopyFilter (
	in_from_filter_id			IN	chain.filter.filter_id%TYPE,
	in_to_filter_id				IN	chain.filter.filter_id%TYPE
);

PROCEDURE DeleteFilter (
	in_filter_id				IN	chain.filter.filter_id%TYPE
);

FUNCTION IsFilterEmpty(
	in_filter_id				IN  chain.filter.filter_id%TYPE
) RETURN NUMBER;

PROCEDURE SaveFilterCondition (
	in_filter_id				IN	qs_filter_condition.filter_id%TYPE,
	in_pos						IN	qs_filter_condition.pos%TYPE,
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_str_val		IN	qs_filter_condition.compare_to_str_val%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition.compare_to_num_val%TYPE,
	in_compare_to_option_id		IN	qs_filter_condition.compare_to_option_id%TYPE,
	in_survey_sid				IN	qs_filter_condition.survey_sid%TYPE,
	in_qs_campaign_sid			IN	qs_filter_condition.qs_campaign_sid%TYPE
);

PROCEDURE SaveFilterConditionGeneral (
	in_filter_id					IN	qs_filter_condition_general.filter_id%TYPE,
	in_pos							IN	qs_filter_condition_general.pos%TYPE,
	in_survey_sid					IN	quick_survey.survey_sid%TYPE,
	in_qs_filter_cond_gen_type_id	IN	qs_filter_cond_gen_type.qs_filter_cond_gen_type_id%TYPE,
	in_comparator					IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_str_val			IN	qs_filter_condition_general.compare_to_str_val%TYPE,
	in_compare_to_num_val			IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	in_qs_campaign_sid				IN	qs_filter_condition_general.qs_campaign_sid%TYPE
);

PROCEDURE DeleteRemainingConditions (
	in_filter_id					IN	qs_filter_condition.filter_id%TYPE,
	in_survey_sid					IN	qs_filter_condition.survey_sid%TYPE,
	in_qs_campaign_sid				IN	qs_filter_condition.qs_campaign_sid%TYPE,
	in_conditions_to_keep			IN	security_pkg.T_SID_IDS
);

FUNCTION HasFilterConditions(
	in_filter_id				IN	chain.filter.filter_id%TYPE
) RETURN NUMBER;

PROCEDURE ClearConditions(
	in_filter_id				IN	chain.filter.filter_id%TYPE
);

PROCEDURE DeleteRemainingFilters (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_survey_sids_to_keep			IN	security_pkg.T_SID_IDS,
	in_campaign_sids_to_keep		IN	security_pkg.T_SID_IDS
);

PROCEDURE GetAllFilterConditions (
	in_filter_id				IN	chain.filter.filter_id%TYPE,
	out_filter_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_filter_cond_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSEC_SetAnswer(
	in_response_id				IN quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN quick_survey_response.last_submission_id%TYPE DEFAULT NULL,
	in_question_lookup_key		IN quick_survey_question.lookup_key%TYPE,
	in_answer					IN VARCHAR2,
	in_report_errors			IN NUMBER DEFAULT 0
);

PROCEDURE UNSEC_SetAnswerScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid				IN	quick_survey_version.survey_sid%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE,
	in_question_version			IN	quick_survey_question.question_version%TYPE,
	in_score					IN	quick_survey_answer.score%TYPE,
	in_max_score				IN	quick_survey_answer.max_score%TYPE
);

PROCEDURE UNSEC_SetAnswerMaxScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid				IN	quick_survey.survey_sid%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE,
	in_question_version			IN	quick_survey_question.question_version%TYPE,
	in_max_score				IN	quick_survey_answer.max_score%TYPE
);

PROCEDURE UNSEC_SetSectionWeight(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid				IN	quick_survey.survey_sid%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE,
	in_question_version			IN	quick_survey_question.question_version%TYPE,
	in_weight					IN	quick_survey_answer.max_score%TYPE
);

FUNCTION GetThresholdFromScore (
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_score					IN	NUMBER
) RETURN quick_survey_submission.score_threshold_id%TYPE;

PROCEDURE CalculateResponseScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	out_score					OUT	quick_survey_answer.score%TYPE,
	out_max_score				OUT	quick_survey_answer.max_score%TYPE,
	out_score_threshold_id		OUT	quick_survey_submission.score_threshold_id%TYPE
);

PROCEDURE CalculateResponseScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE
);

PROCEDURE GetScoreIndVals
(
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditScoreIndVals
(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierScoreIndVals
(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionScoreIndVals
(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
) ;

PROCEDURE GetSurveyLangs (
	in_survey_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllSurveyLangs (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddSurveyLang (
	in_survey_sid				IN  security_pkg.T_SID_ID,
	in_lang						IN	VARCHAR2
);

PROCEDURE DeleteSurveyLang (
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_survey_sid				IN  security_pkg.T_SID_ID,
	in_lang						IN	VARCHAR2
);

FUNCTION IsSubmitted (
	in_response_guid			IN	quick_survey_response.guid%TYPE
) RETURN NUMBER;

PROCEDURE SetCustomQuestionType (
	in_description				IN	qs_custom_question_type.description%TYPE,
	in_js_include				IN	qs_custom_question_type.js_include%TYPE,
	in_js_class					IN	qs_custom_question_type.js_class%TYPE,
	in_cs_class					IN	qs_custom_question_type.cs_class%TYPE
);

FUNCTION GetScoreTypeId (
	in_lookup_key				IN	score_type.lookup_key%TYPE
) RETURN score_type.score_type_id%TYPE;

PROCEDURE GetScoreTypes(
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_score_thresh_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_score_typ_aud_typ_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteScoreType(
	in_score_type_id	IN	score_type.score_type_id%TYPE
);

PROCEDURE SaveScoreType (
	in_score_type_id		IN	score_type.score_type_id%TYPE,
	in_label				IN	score_type.label%TYPE,
	in_pos					IN	score_type.pos%TYPE,
	in_hidden				IN	score_type.hidden%TYPE,
	in_allow_manual_set		IN	score_type.allow_manual_set%TYPE,
	in_lookup_key			IN	score_type.lookup_key%TYPE,
	in_applies_to_supplier	IN	score_type.applies_to_supplier%TYPE,
	in_reportable_months	IN	score_type.reportable_months%TYPE,
	in_format_mask			IN	score_type.format_mask%TYPE DEFAULT '#,##0.0%',
	in_ask_for_comment		IN	score_type.ask_for_comment%TYPE DEFAULT 'none',
	in_applies_to_surveys	IN	score_type.applies_to_surveys%TYPE DEFAULT 0,
	in_applies_to_ncs		IN	score_type.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_regions	IN	score_type.applies_to_regions%TYPE DEFAULT 0,
	in_min_score			IN	score_type.min_score%TYPE DEFAULT NULL,
	in_max_score			IN	score_type.max_score%TYPE DEFAULT NULL,
	in_start_score			IN	score_type.start_score%TYPE DEFAULT 0,
	in_norm_to_max_score	IN	score_type.normalise_to_max_score%TYPE DEFAULT 0,
	in_applies_to_audits	IN	score_type.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_supp_rels	IN	score_type.applies_to_supp_rels%TYPE DEFAULT 0,
	in_applies_to_permits	IN	score_type.applies_to_permits%TYPE DEFAULT 0,
	out_score_type_id		OUT	score_type.score_type_id%TYPE
);

PROCEDURE SaveScoreType (
	in_score_type_id		IN	score_type.score_type_id%TYPE,
	in_label				IN	score_type.label%TYPE,
	in_pos					IN	score_type.pos%TYPE,
	in_hidden				IN	score_type.hidden%TYPE,
	in_allow_manual_set		IN	score_type.allow_manual_set%TYPE,
	in_lookup_key			IN	score_type.lookup_key%TYPE,
	in_applies_to_supplier	IN	score_type.applies_to_supplier%TYPE,
	in_reportable_months	IN	score_type.reportable_months%TYPE,
	in_format_mask			IN	score_type.format_mask%TYPE DEFAULT '#,##0.0%',
	in_ask_for_comment		IN	score_type.ask_for_comment%TYPE DEFAULT 'none',
	in_applies_to_surveys	IN	score_type.applies_to_surveys%TYPE DEFAULT 0,
	in_applies_to_ncs		IN	score_type.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_regions	IN	score_type.applies_to_regions%TYPE DEFAULT 0,
	in_min_score			IN	score_type.min_score%TYPE DEFAULT NULL,
	in_max_score			IN	score_type.max_score%TYPE DEFAULT NULL,
	in_start_score			IN	score_type.start_score%TYPE DEFAULT 0,
	in_norm_to_max_score	IN	score_type.normalise_to_max_score%TYPE DEFAULT 0,
	in_applies_to_audits	IN	score_type.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_supp_rels	IN	score_type.applies_to_supp_rels%TYPE DEFAULT 0,
	in_applies_to_permits	IN	score_type.applies_to_permits%TYPE DEFAULT 0,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetScoreTypePositions(
	in_score_type_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SaveScoreThreshold(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	in_description			IN	score_threshold.description%TYPE,
	in_max_value			IN	score_threshold.max_value%TYPE,
	in_text_colour			IN	score_threshold.text_colour%TYPE,
	in_background_colour	IN	score_threshold.background_colour%TYPE,
	in_bar_colour			IN	score_threshold.bar_colour%TYPE,
	in_score_type_id		IN	score_threshold.score_type_id%TYPE,
	in_lookup_key			IN	score_threshold.lookup_key%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteRemovedThresholds (
	in_score_type_id		IN	score_type.score_type_id%TYPE,
	in_thresholds_to_keep	IN	security_pkg.T_SID_IDS
);

PROCEDURE ChangeThresholdIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE GetThresholdIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ChangeDashboardIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE GetDashboardIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetWorkflowState(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_guid					IN	quick_survey_response.guid%TYPE,
	out_state				OUT	security_pkg.T_OUTPUT_CUR,
	out_actions				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetNextWorkflowState(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_next_state_id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	out_next_state_editable	OUT	NUMBER
);

PROCEDURE GetMySurveys (
	in_parent_region_sid	IN	security_pkg.T_SID_ID,
	in_remove_submitted		IN	NUMBER DEFAULT MY_SURVEYS_SHOW_ALL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateScoreThresholdMeasure (
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	out_measure_sid				OUT	security_pkg.T_SID_ID
);

PROCEDURE SynchroniseIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE := NULL
);

PROCEDURE SynchroniseIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE := NULL,
	in_question_ids 			IN  security_pkg.T_SID_IDS
);

PROCEDURE Internal_SynchroniseIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE := NULL,
	in_question_ids 			IN  security_pkg.T_SID_IDS
);

PROCEDURE FixUserMappedIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID
);

/*Returns historic submissions (not draft version)*/
PROCEDURE GetSubmissions(
	in_survey_response_id	IN quick_survey_response.survey_response_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCSClass(
	in_survey_sid			IN	security_pkg.T_SID_ID
) RETURN qs_custom_question_type.cs_class%TYPE;

/**
 * When a quick survey gets restored from trash, we need to re-create it's web resource row otherwise the restoration will fail
 *
 * @in_object_sid			SID of the object.
 * @in_object_name			Name of the securable object.
 */
PROCEDURE RecreateQuickSurveyWebRes(
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_object_name		IN	security.securable_object.Name%TYPE,
	in_class_id			IN  security_pkg.T_SID_ID
);

PROCEDURE CopyAnswersFromPrevious(
	in_survey_sid					IN security_pkg.T_SID_ID,
	in_response_id					IN quick_survey_response.survey_response_id%TYPE,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_only_same_survey				IN NUMBER DEFAULT 0 --if this is 1 it will copy only from another response of the same survey, otherwise it will copy from any survey that has questions with the same lookup_keys
);

PROCEDURE GetSurveyChangeList(
	in_act_id			IN security.security_pkg.T_ACT_ID,
	in_survey_sid		IN security.security_pkg.T_SID_ID,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
);

FUNCTION GetResponseRegionSid (
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE
)RETURN security_pkg.T_SID_ID;

PROCEDURE SyncAnswerScores(
	in_survey_response_id		quick_survey_submission.survey_response_Id%TYPE,
	in_survey_submission_id		quick_survey_submission.submission_Id%TYPE,
	in_survey_version			quick_survey_submission.survey_version%TYPE
);

PROCEDURE GetSurveyTypes(
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveSurveyType(
	in_quick_survey_type_id		IN quick_survey_type.quick_survey_type_id%TYPE,
	in_description				IN quick_survey_type.description%TYPE,
	in_enable_question_count	IN quick_survey_type.enable_question_count%TYPE,
	in_show_answer_set_dtm		IN quick_survey_type.show_answer_set_dtm%TYPE,
	in_oth_txt_req_for_score	IN quick_survey_type.other_text_req_for_score%TYPE,
	in_tearoff_toolbar 			IN quick_survey_type.tearoff_toolbar%TYPE DEFAULT 0,
	in_cs_class					IN quick_survey_type.cs_class%TYPE,
	in_helper_pkg				IN quick_survey_type.helper_pkg%TYPE,
	in_capture_geo_location		IN quick_survey_type.capture_geo_location%TYPE DEFAULT 0,
	in_enable_response_import   IN quick_survey_type.enable_response_import%TYPE DEFAULT 1,	
	out_quick_survey_type_id	OUT quick_survey_type.quick_survey_type_id%TYPE
);

PROCEDURE SetSurveyType (
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_survey_type_id				IN	quick_survey_type.quick_survey_type_id%TYPE
);

PROCEDURE GetAllCountQuestionsIds(
	in_survey_sid		IN security.security_pkg.T_SID_ID,
	in_survey_version	IN quick_survey_response.survey_version%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAnsweredQuestionIds(
	in_response_id			IN quick_survey_submission.survey_response_Id%TYPE,
	in_submission_id		IN quick_survey_submission.submission_Id%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
);

FUNCTION IsQuestionCountEnabled(
	in_quick_survey_type_id		IN quick_survey.quick_survey_type_id%TYPE
)RETURN NUMBER;

PROCEDURE UpdateLinkedResponse(
	in_ref_response_id				IN quick_survey_submission.survey_response_id%TYPE,
	in_target_response_id			IN quick_survey_submission.survey_response_id%TYPE
);

PROCEDURE CopyAnswer (
	in_from_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_from_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_from_question_id			IN	quick_survey_question.question_id%TYPE,
	in_to_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	--in_to_submission_id			IN	quick_survey_submission.submission_id%TYPE, --always copies into submission 0, and also doesn't overwrite (should it?)
	in_to_question_id			IN	quick_survey_question.question_id%TYPE
);

PROCEDURE GetCssStyles(
	out_css_styles_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateScoreTypeAggType (
	in_analytic_function			score_type_agg_type.analytic_function%TYPE,
	in_score_type_id				score_type_agg_type.score_type_id%TYPE,
	in_applies_to_nc_score			score_type_agg_type.applies_to_nc_score%TYPE,
	in_applies_to_primary_survey	score_type_agg_type.applies_to_primary_audit_survy%TYPE,
	in_applies_to_audits 			score_type_agg_type.applies_to_audits%TYPE,
	in_ia_type_survey_group_id		score_type_agg_type.ia_type_survey_group_id%TYPE
);

PROCEDURE GetSurveyVersions(
	in_survey_sid		IN security.security_pkg.T_SID_ID,
	in_include_zero		IN NUMBER,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUpgradableSubmissions(
	in_survey_sid			IN security.security_pkg.T_SID_ID,
	in_survey_version_from	IN quick_survey_submission.survey_version%TYPE,
	in_survey_version_to	IN quick_survey_submission.survey_version%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpgradeSubmissionToVersion(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_survey_version		IN	quick_survey_version.survey_version%TYPE
);

PROCEDURE RescoreAnswers(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE
);

PROCEDURE UNSEC_RescoreAnswers(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE
);

PROCEDURE FinaliseSubmissionUpgrade(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE
);
PROCEDURE FilterCompanyResponseStatuses(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE FilterIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
);

PROCEDURE UNSEC_PublishRegionScore(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_score					IN	quick_survey_submission.overall_score%TYPE,
	in_threshold_id				IN	quick_survey_submission.score_threshold_id%TYPE,
	in_comment_text				IN	region_score_log.comment_text%TYPE DEFAULT NULL
);


PROCEDURE PopulateExtendedFolderSearch (
	in_parent_sid		security.security_pkg.T_SID_ID,
	in_so_class_id   	security.securable_object_class.class_id%TYPE,
	in_search_term		VARCHAR2
);

PROCEDURE SetScoreTypeAuditTypes (
	in_score_type_id				IN	score_type.score_type_id%TYPE,
	in_associated_audit_type_ids	IN	security_pkg.T_SID_IDS
);

FUNCTION GetResponseCapability(
	in_flow_item		csr.flow_item.flow_item_id%TYPE
) RETURN NUMBER;

FUNCTION CheckResponseCapability(
	in_flow_item		csr.flow_item.flow_item_id%TYPE,
	in_expected_perm	NUMBER
) RETURN NUMBER;

FUNCTION FlowItemRecordExists(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetSurveySidsForLookupKey(
	in_survey_lookup_key	IN	quick_survey.lookup_key%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

END quick_survey_pkg;
/
