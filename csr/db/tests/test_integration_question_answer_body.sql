CREATE OR REPLACE PACKAGE BODY csr.test_integration_question_answer_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_label					VARCHAR2(255);
	v_count					NUMBER;
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	DELETE FROM integration_question_answer
	 WHERE question_ref LIKE 'TestIQA_%';
END;

PROCEDURE TestAddKeyFields AS
	v_new_count			NUMBER;
	v_ref				VARCHAR2(255) := 'TestIQA__Add';
	v_last_updated		DATE;
BEGIN
	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref => 'TestIQA_Parent',
		in_question_ref => v_ref
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');

	SELECT last_updated
	  INTO v_last_updated
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertIsNotNull(v_last_updated, 'last_updated');
END;

PROCEDURE TestAddAllFields AS
	v_new_count				NUMBER;
	v_ref					VARCHAR2(255) := 'TestIQA__AddAll';
	v_internal_audit_sid	integration_question_answer.internal_audit_sid%TYPE;
	v_questionnaire_name	integration_question_answer.questionnaire_name%TYPE;
	v_section_name			integration_question_answer.section_name%TYPE;
	v_section_code			integration_question_answer.section_code%TYPE;
	v_section_score			integration_question_answer.section_score%TYPE;
	v_subsection_name		integration_question_answer.subsection_name%TYPE;
	v_subsection_code		integration_question_answer.subsection_code%TYPE;
	v_question_text			integration_question_answer.question_text%TYPE;
	v_rating				integration_question_answer.rating%TYPE;
	v_conclusion			integration_question_answer.conclusion%TYPE;
	v_answer				integration_question_answer.answer%TYPE;
	v_data_points			integration_question_answer.data_points%TYPE;
	v_last_updated			integration_question_answer.last_updated%TYPE;
BEGIN
	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref			=> 'TestIQA_Parent',
		in_question_ref			=> v_ref,
		in_questionnaire_name   => 'qname',
		in_internal_audit_sid	=> NULL,
		in_section_name			=> 'sn',
		in_section_code			=> 'sc',
		in_section_score		=> 12345.67891,
		in_subsection_name		=> 'ssn',
		in_subsection_code		=> 'ssc',
		in_question_text		=> 'qt',
		in_rating				=> 'r',
		in_conclusion			=> 'c',
		in_answer				=> 'a',
		in_data_points			=> 'dp1,dp2',
		in_last_updated			=> DATE '2021-01-02'
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');

	SELECT internal_audit_sid, questionnaire_name, section_name, section_code, section_score, subsection_name, subsection_code,
			question_text, rating, conclusion, answer, data_points, last_updated
	  INTO	v_internal_audit_sid,
			v_questionnaire_name,
			v_section_name,
			v_section_code,
			v_section_score,
			v_subsection_name,
			v_subsection_code,
			v_question_text,
			v_rating,
			v_conclusion,
			v_answer,
			v_data_points,
			v_last_updated
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertIsNull(v_internal_audit_sid, 'internal_audit_sid');
	unit_test_pkg.AssertAreEqual(v_questionnaire_name, 'qname', 'questionnaire_name');
	unit_test_pkg.AssertAreEqual(v_section_name, 'sn', 'section_name');
	unit_test_pkg.AssertAreEqual(v_section_code, 'sc', 'section_code');
	unit_test_pkg.AssertAreEqual(v_section_score, 12345.67891, 'section_score');
	unit_test_pkg.AssertAreEqual(v_subsection_name, 'ssn', 'subsection_name');
	unit_test_pkg.AssertAreEqual(v_subsection_code, 'ssc', 'subsection_code');
	unit_test_pkg.AssertAreEqual(v_question_text, 'qt', 'question_text');
	unit_test_pkg.AssertAreEqual(v_rating, 'r', 'rating');
	unit_test_pkg.AssertAreEqual(v_conclusion, TO_CLOB('c'), 'conclusion');
	unit_test_pkg.AssertAreEqual(v_answer, TO_CLOB('a'), 'answer');
	unit_test_pkg.AssertAreEqual(v_data_points, TO_CLOB('dp1,dp2'), 'data_points');
	unit_test_pkg.AssertAreEqual(v_last_updated, DATE '2021-01-02', 'last_updated');
END;

PROCEDURE TestUpdate AS
	v_ref					VARCHAR2(255) := 'TestIQA__Update';
	v_answer				VARCHAR2(255) := 'TestIQA__Update';
	v_answer_updated		VARCHAR2(255) := 'TestIQA__Update_Updated';
	v_new_count				NUMBER;
BEGIN
	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref => 'TestIQA_Parent',
		in_question_ref => v_ref,
		in_answer => v_answer
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');

	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref => 'TestIQA_Parent',
		in_question_ref => v_ref,
		in_answer => v_answer_updated
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');
END;

PROCEDURE TestUpdateAllFields AS
	v_ref					VARCHAR2(255) := 'TestIQA__UpdateAllFields';
	v_new_count				NUMBER;

	v_internal_audit_sid	integration_question_answer.internal_audit_sid%TYPE;
	v_questionnaire_name	integration_question_answer.questionnaire_name%TYPE;
	v_section_name			integration_question_answer.section_name%TYPE;
	v_section_code			integration_question_answer.section_code%TYPE;
	v_section_score			integration_question_answer.section_score%TYPE;
	v_subsection_name		integration_question_answer.subsection_name%TYPE;
	v_subsection_code		integration_question_answer.subsection_code%TYPE;
	v_question_text			integration_question_answer.question_text%TYPE;
	v_rating				integration_question_answer.rating%TYPE;
	v_conclusion			integration_question_answer.conclusion%TYPE;
	v_answer				integration_question_answer.answer%TYPE;
	v_data_points			integration_question_answer.data_points%TYPE;
	v_last_updated			integration_question_answer.last_updated%TYPE;
BEGIN
	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref => 'TestIQA_Parent',
		in_question_ref => v_ref,
		in_answer => 'Initial answer'
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');

	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref 			=> 'TestIQA_Parent',
		in_question_ref 		=> v_ref,
		in_questionnaire_name   => 'qname',
		in_internal_audit_sid	=> NULL,
		in_section_name			=> 'sn',
		in_section_code			=> 'sc',
		in_section_score		=> 100,
		in_subsection_name		=> 'ssn',
		in_subsection_code		=> 'ssc',
		in_question_text		=> 'qt',
		in_rating				=> 'r',
		in_conclusion			=> 'c',
		in_answer				=> 'Updated answer',
		in_data_points			=> 'dp1,dp2',
		in_last_updated			=> DATE '2021-01-02'
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');

	
	SELECT internal_audit_sid, questionnaire_name, section_name, section_code, section_score, subsection_name, subsection_code,
			question_text, rating, conclusion, answer, data_points, last_updated
	  INTO	v_internal_audit_sid,
			v_questionnaire_name,
			v_section_name,
			v_section_code,
			v_section_score,
			v_subsection_name,
			v_subsection_code,
			v_question_text,
			v_rating,
			v_conclusion,
			v_answer,
			v_data_points,
			v_last_updated
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertIsNull(v_internal_audit_sid, 'internal_audit_sid');
	unit_test_pkg.AssertAreEqual(v_questionnaire_name, 'qname', 'questionnaire_name');
	unit_test_pkg.AssertAreEqual(v_section_name, 'sn', 'section_name');
	unit_test_pkg.AssertAreEqual(v_section_code, 'sc', 'section_code');
	unit_test_pkg.AssertAreEqual(v_section_score, 100, 'section_score');
	unit_test_pkg.AssertAreEqual(v_subsection_name, 'ssn', 'subsection_name');
	unit_test_pkg.AssertAreEqual(v_subsection_code, 'ssc', 'subsection_code');
	unit_test_pkg.AssertAreEqual(v_question_text, 'qt', 'question_text');
	unit_test_pkg.AssertAreEqual(v_rating, 'r', 'rating');
	unit_test_pkg.AssertAreEqual(v_conclusion, TO_CLOB('c'), 'conclusion');
	unit_test_pkg.AssertAreEqual(v_answer, TO_CLOB('Updated answer'), 'answer');
	unit_test_pkg.AssertAreEqual(v_data_points, TO_CLOB('dp1,dp2'), 'data_points');
	unit_test_pkg.AssertAreEqual(v_last_updated, DATE '2021-01-02', 'last_updated');
END;

PROCEDURE TestDelete AS
	v_ref					VARCHAR2(255) := 'TestIQA_Delete';
	v_new_count				NUMBER;
BEGIN
	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref => 'TestIQA_Parent',
		in_question_ref => v_ref,
		in_internal_audit_sid => NULL
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(1, v_new_count, 'Expected 1');

	integration_question_answer_pkg.DeleteIntegrationQuestionAnswer(
		in_parent_ref => 'TestIQA_Parent',
		in_question_ref => v_ref
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM integration_question_answer
	 WHERE question_ref = v_ref;

	unit_test_pkg.AssertAreEqual(0, v_new_count, 'Expected none');
END;

PROCEDURE TestGetOne AS
	v_test_parent_ref					VARCHAR2(255) := 'TestIQA_Parent';
	v_test_question_ref					VARCHAR2(255) := 'TestIQA_GetSelectedRecord';
	v_count								NUMBER := 0;
	v_out_cur							SYS_REFCURSOR;

	v_parent_ref			integration_question_answer.parent_ref%TYPE;	
	v_questionnaire_name	integration_question_answer.questionnaire_name%TYPE;
	v_question_ref			integration_question_answer.question_ref%TYPE;
	v_internal_audit_sid	integration_question_answer.internal_audit_sid%TYPE;
	v_section_name			integration_question_answer.section_name%TYPE;
	v_section_code			integration_question_answer.section_code%TYPE;
	v_section_score			integration_question_answer.section_score%TYPE;
	v_subsection_name		integration_question_answer.subsection_name%TYPE;
	v_subsection_code		integration_question_answer.subsection_code%TYPE;
	v_question_text			integration_question_answer.question_text%TYPE;
	v_rating				integration_question_answer.rating%TYPE;
	v_conclusion			integration_question_answer.conclusion%TYPE;
	v_answer				integration_question_answer.answer%TYPE;
	v_data_points			integration_question_answer.data_points%TYPE;
	v_last_updated			integration_question_answer.last_updated%TYPE;
	v_id					integration_question_answer.id%TYPE;
BEGIN

	delete from integration_question_answer where parent_ref = v_test_parent_ref;

	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref 	=> v_test_parent_ref,
		in_question_ref => v_test_question_ref
	);

	integration_question_answer_pkg.GetIntegrationQuestionAnswer(
		in_parent_ref 	=> v_test_parent_ref,
		out_cur 		=> v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_parent_ref, v_questionnaire_name, v_question_ref, v_internal_audit_sid,
			v_section_name, v_section_code, v_section_score,
			v_subsection_name, v_subsection_code, v_question_text, v_rating, v_conclusion, v_answer,
			v_data_points, v_last_updated, v_id;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Only single record must be returned');
END;

PROCEDURE TestGetAll AS
	v_ref					VARCHAR2(255) := 'TestIQA_GetAllRecords';
	v_count					NUMBER := 0;
	v_out_cur				SYS_REFCURSOR;
	v_index_1				NUMBER;
	v_index_2				NUMBER;

	v_parent_ref			integration_question_answer.parent_ref%TYPE;
	v_questionnaire_name	integration_question_answer.questionnaire_name%TYPE;
	v_question_ref			integration_question_answer.question_ref%TYPE;
	v_internal_audit_sid	integration_question_answer.internal_audit_sid%TYPE;
	v_section_name			integration_question_answer.section_name%TYPE;
	v_section_code			integration_question_answer.section_code%TYPE;
	v_section_score			integration_question_answer.section_score%TYPE;
	v_subsection_name		integration_question_answer.subsection_name%TYPE;
	v_subsection_code		integration_question_answer.subsection_code%TYPE;
	v_question_text			integration_question_answer.question_text%TYPE;
	v_rating				integration_question_answer.rating%TYPE;
	v_conclusion			integration_question_answer.conclusion%TYPE;
	v_answer				integration_question_answer.answer%TYPE;
	v_data_points			integration_question_answer.data_points%TYPE;
	v_last_updated			integration_question_answer.last_updated%TYPE;
	v_id					integration_question_answer.id%TYPE;
BEGIN
	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref 	=> 'TestIQA_Parent',
		in_question_ref => v_ref || '002'
	);

	integration_question_answer_pkg.UpsertIntegrationQuestionAnswer(
		in_parent_ref 	=> 'TestIQA_Parent',
		in_question_ref => v_ref || '001'
	);

	integration_question_answer_pkg.GetIntegrationQuestionAnswers(
		out_cur 		 => v_out_cur
	);

	LOOP
		FETCH v_out_cur INTO v_parent_ref, v_questionnaire_name, v_question_ref, v_internal_audit_sid,
			v_section_name, v_section_code, v_section_score,
			v_subsection_name, v_subsection_code, v_question_text, v_rating, v_conclusion, v_answer,
			v_data_points, v_last_updated, v_id;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count +1;

		IF v_question_ref = v_ref||'_001' THEN
			v_index_1 := v_count;
		END IF;
		IF v_question_ref = v_ref||'_002' THEN
			v_index_2 := v_count;
		END IF;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_index_1 < v_index_2, 'Sort order should be correct.');
	unit_test_pkg.AssertIsTrue(v_count > 1, 'Number of saved records should be more than one');
END;



PROCEDURE TearDownFixture 
AS
	v_count				NUMBER;
	v_label				VARCHAR2(255);
	v_updated_label		VARCHAR2(255);

BEGIN
	DELETE FROM integration_question_answer
	 WHERE question_ref LIKE 'TestIQA_%';
END;

END test_integration_question_answer_pkg;
/
