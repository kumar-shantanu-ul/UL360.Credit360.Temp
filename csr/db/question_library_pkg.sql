CREATE OR REPLACE PACKAGE csr.question_library_pkg AS


PROCEDURE GetQuestion(
	in_question_id			IN	question_version.question_id%TYPE,
	in_version				IN	question_version.question_version%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_version_cur 		OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_options_tags_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionHistory(
	in_question_id		IN	question_version.question_id%TYPE,
	out_versions_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateQuestion(
	in_question_type			IN	question.question_type%TYPE,
	in_custom_question_type_id	IN	question.custom_question_type_id%TYPE,
	in_lookup_key				IN	question.lookup_key%TYPE,
	in_maps_to_ind_sid			IN	question.maps_to_ind_sid%TYPE,
	in_measure_sid				IN	question.measure_sid%TYPE,
	out_question_id				OUT	question.question_id%TYPE
);

PROCEDURE SaveQuestion(
	in_question_id				IN	question_version.question_id%TYPE,
	in_question_version			IN	question_version.question_version%TYPE,
	in_question_draft			IN	question_version.question_draft%TYPE,
	in_parent_id				IN	question_version.parent_id%TYPE,
	in_parent_version			IN	question_version.parent_version%TYPE,
	in_pos						IN	question_version.pos%TYPE,
	in_label					IN	question_version.label%TYPE,
	in_score					IN	question_version.score%TYPE,
	in_max_score				IN	question_version.max_score%TYPE,
	in_upload_score				IN	question_version.upload_score%TYPE,
	in_weight					IN	question_version.weight%TYPE,
	in_dont_normalise_score		IN	question_version.dont_normalise_score%TYPE,
	in_has_score_expression		IN	question_version.has_score_expression%TYPE,
	in_has_max_score_expr		IN	question_version.has_max_score_expr%TYPE,
	in_remember_answer			IN	question_version.remember_answer%TYPE,
	in_count_question			IN	question_version.count_question%TYPE,
	in_action					IN	question_version.action%TYPE,
	in_question_xml				IN	question_version.question_xml%TYPE,
	in_tag_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_tag_show_in_survey		IN	chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE PublishQuestion(
	in_question_id				IN	question_version.question_id%TYPE,
	in_question_version			IN	question_version.question_version%TYPE
);

PROCEDURE SaveQuestionOption(
	in_question_option_id			IN	question_option.question_option_id%TYPE, 
	in_question_id					IN	question_option.question_id%TYPE,
	in_question_version				IN	question_option.question_version%TYPE,
	in_question_draft				IN	question_option.question_draft%TYPE,
	in_pos							IN	question_option.pos%TYPE,
	in_label						IN	question_option.label%TYPE,
	in_score						IN	question_option.score%TYPE,
	in_color						IN	question_option.color%TYPE,
	in_lookup_key					IN	question_option.lookup_key%TYPE,
	in_maps_to_ind_sid				IN	question_option.maps_to_ind_sid%TYPE,
	in_option_action				IN	question_option.option_action%TYPE,
	in_non_compliance_popup			IN	question_option.non_compliance_popup%TYPE,
	in_non_comp_default_id			IN	question_option.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN	question_option.non_compliance_type_id%TYPE,
	in_non_compliance_label			IN	question_option.non_compliance_label%TYPE,
	in_non_compliance_detail		IN	question_option.non_compliance_detail%TYPE,
	in_non_comp_root_cause			IN	question_option.non_comp_root_cause%TYPE,
	in_non_comp_suggested_action	IN	question_option.non_comp_suggested_action%TYPE,
	in_question_option_xml			IN	question_option.question_option_xml%TYPE,
	in_tag_ids						IN  chain.helper_pkg.T_NUMBER_ARRAY,
	out_question_option_id			OUT	question_option.question_option_id%TYPE
);

END question_library_pkg;
/

