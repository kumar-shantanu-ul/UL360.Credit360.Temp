CREATE OR REPLACE PACKAGE CSR.integration_question_answer_pkg AS

PROCEDURE GetIntegrationQuestionAnswers(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetIntegrationQuestionAnswer(
	in_parent_ref			IN	integration_question_answer.parent_ref%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UpsertIntegrationQuestionAnswer(
	in_parent_ref			IN	integration_question_answer.parent_ref%TYPE,
	in_question_ref			IN	integration_question_answer.question_ref%TYPE,
	in_questionnaire_name	IN  integration_question_answer.questionnaire_name%TYPE DEFAULT NULL,
	in_internal_audit_sid	IN	integration_question_answer.internal_audit_sid%TYPE DEFAULT NULL,
	in_section_name			IN	integration_question_answer.section_name%TYPE DEFAULT NULL,
	in_section_code			IN	integration_question_answer.section_code%TYPE DEFAULT NULL,
	in_section_score		IN	integration_question_answer.section_score%TYPE DEFAULT NULL,
	in_subsection_name		IN	integration_question_answer.subsection_name%TYPE DEFAULT NULL,
	in_subsection_code		IN	integration_question_answer.subsection_code%TYPE DEFAULT NULL,
	in_question_text		IN	integration_question_answer.question_text%TYPE DEFAULT NULL,
	in_rating				IN	integration_question_answer.rating%TYPE DEFAULT NULL,
	in_conclusion			IN	integration_question_answer.conclusion%TYPE DEFAULT NULL,
	in_answer				IN	integration_question_answer.answer%TYPE DEFAULT NULL,
	in_data_points			IN	integration_question_answer.data_points%TYPE DEFAULT NULL,
	in_last_updated			IN	integration_question_answer.last_updated%TYPE DEFAULT SYSDATE
);

PROCEDURE DeleteIntegrationQuestionAnswer(
	in_parent_ref			IN	integration_question_answer.parent_ref%TYPE,
	in_question_ref			IN	integration_question_answer.question_ref%TYPE
);

END integration_question_answer_pkg;
/
