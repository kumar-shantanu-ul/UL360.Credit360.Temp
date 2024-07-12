CREATE OR REPLACE PACKAGE BODY CSR.integration_question_answer_pkg AS

PROCEDURE GetIntegrationQuestionAnswers(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT parent_ref, questionnaire_name, question_ref, internal_audit_sid, section_name, section_code, section_score,
			   subsection_name, subsection_code, question_text, rating, conclusion, answer,
			   data_points, last_updated, id
		  FROM integration_question_answer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		ORDER BY parent_ref, question_ref, internal_audit_sid NULLS FIRST;
END;

PROCEDURE GetIntegrationQuestionAnswer(
	in_parent_ref			IN	integration_question_answer.parent_ref%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT parent_ref, questionnaire_name, question_ref, internal_audit_sid, section_name, section_code, section_score,
			   subsection_name, subsection_code, question_text, rating, conclusion, answer,
			   data_points, last_updated, id
		  FROM integration_question_answer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_ref = in_parent_ref;
END;

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
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied upserting IQA.');
	END IF;
	
	BEGIN
		UPDATE integration_question_answer
		   SET internal_audit_sid = in_internal_audit_sid,
			   section_name = in_section_name,
			   section_code = in_section_code,
			   section_score = in_section_score,
			   subsection_name = in_subsection_name,
			   subsection_code = in_subsection_code,
			   question_text = in_question_text,
			   rating = in_rating,
			   conclusion = in_conclusion,
			   answer = in_answer,
			   data_points = in_data_points,
			   last_updated = in_last_updated,
			   questionnaire_name = in_questionnaire_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_ref = in_parent_ref
		   AND question_ref = in_question_ref;

		IF SQL%ROWCOUNT = 0 THEN
			INSERT INTO integration_question_answer (parent_ref, questionnaire_name, question_ref, internal_audit_sid,
			   section_name, section_code, section_score,
			   subsection_name, subsection_code, question_text, rating, conclusion, answer,
			   data_points, last_updated, id)
			VALUES (in_parent_ref, in_questionnaire_name, in_question_ref, in_internal_audit_sid,
					in_section_name, in_section_code, in_section_score,
					in_subsection_name, in_subsection_code, in_question_text, in_rating, in_conclusion, in_answer,
					in_data_points, in_last_updated, INTEGRATION_QUESTION_ANSWER_ID_SEQ.NEXTVAL);
			
			csr_data_pkg.WriteAuditLogEntry(
				SYS_CONTEXT('SECURITY', 'ACT'), 
				csr_data_pkg.AUDIT_TYPE_IQA,
				SYS_CONTEXT('SECURITY', 'APP'),
				in_internal_audit_sid,
				'Inserted IQA',
				in_parent_ref,
				in_question_ref
			);
		ELSE
			csr_data_pkg.WriteAuditLogEntry(
				SYS_CONTEXT('SECURITY', 'ACT'), 
				csr_data_pkg.AUDIT_TYPE_IQA,
				SYS_CONTEXT('SECURITY', 'APP'),
				in_internal_audit_sid,
				'Updated IQA',
				in_parent_ref,
				in_question_ref
			);
		END IF;
	END;	
END;


PROCEDURE DeleteIntegrationQuestionAnswer(
	in_parent_ref			IN	integration_question_answer.parent_ref%TYPE,
	in_question_ref			IN	integration_question_answer.question_ref%TYPE
)
AS
	v_internal_audit_sid	integration_question_answer.internal_audit_sid%TYPE;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting IQA.');
	END IF;
	
	SELECT internal_audit_sid
	  INTO v_internal_audit_sid
	  FROM integration_question_answer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_ref = in_parent_ref
	   AND question_ref = in_question_ref;

	DELETE FROM integration_question_answer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_ref = in_parent_ref
	   AND question_ref = in_question_ref;

	IF SQL%ROWCOUNT > 0
	THEN
		csr_data_pkg.WriteAuditLogEntry(
			SYS_CONTEXT('SECURITY', 'ACT'), 
			csr_data_pkg.AUDIT_TYPE_IQA,
			SYS_CONTEXT('SECURITY', 'APP'),
			v_internal_audit_sid,
			'Deleted IQA',
			in_parent_ref,
			in_question_ref
		);
	END IF;
END;

END integration_question_answer_pkg;
/
