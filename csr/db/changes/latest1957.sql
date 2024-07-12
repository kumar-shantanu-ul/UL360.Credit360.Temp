-- Please update version.sql too -- this keeps clean builds in sync
define version=1957
@update_header

CREATE TABLE CSR.QS_FILTER_COND_GEN_TYPE(
    QS_FILTER_COND_GEN_TYPE_ID		NUMBER(10, 0)		NOT NULL,
    CONDITION_CLASS					VARCHAR2(50)		NOT NULL,
	QUESTION_LABEL					VARCHAR2(100)		NOT NULL,
	CONSTRAINT PK_QS_FILTER_COND_GEN_TYPE PRIMARY KEY (QS_FILTER_COND_GEN_TYPE_ID)
);

CREATE TABLE CSR.QS_FILTER_CONDITION_GENERAL(
    APP_SID							NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_ID						NUMBER(10, 0)     NOT NULL,
    QS_FILTER_CONDITION_GENERAL_ID	NUMBER(10, 0)     NOT NULL,
	SURVEY_SID						NUMBER(10, 0)     NOT NULL,
	QS_FILTER_COND_GEN_TYPE_ID		NUMBER(10, 0)     NOT NULL,
    COMPARATOR						VARCHAR2(20),
    COMPARE_TO_STR_VAL				VARCHAR2(2047),
    COMPARE_TO_NUM_VAL				NUMBER(10, 0),
    CONSTRAINT PK_QS_FILTER_CONDITION_GENERAL PRIMARY KEY (APP_SID, FILTER_ID, QS_FILTER_CONDITION_GENERAL_ID),
	CONSTRAINT FK_QS_FILTER_COND_GEN_TYPE FOREIGN KEY 
		(QS_FILTER_COND_GEN_TYPE_ID) REFERENCES CSR.QS_FILTER_COND_GEN_TYPE(QS_FILTER_COND_GEN_TYPE_ID) 
		ON DELETE CASCADE,
	CONSTRAINT FK_QS_FILTER_COND_GEN_SURVEY FOREIGN KEY 
		(APP_SID, SURVEY_SID) REFERENCES CSR.QUICK_SURVEY(APP_SID, SURVEY_SID) 
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.QS_FILTER_COND_GEN_TYPE(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    QS_FILTER_COND_GEN_TYPE_ID		NUMBER(10, 0)		NOT NULL,
    CONDITION_CLASS					VARCHAR2(50)		NOT NULL,
	QUESTION_LABEL					VARCHAR2(100)		NOT NULL,
	CONSTRAINT PK_QS_FILTER_COND_GEN_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, QS_FILTER_COND_GEN_TYPE_ID),
	CONSTRAINT FK_QS_FILTER_COND_GEN_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.QS_FILTER_CONDITION_GENERAL(
    CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FILTER_ID							NUMBER(10, 0)     NOT NULL,
    QS_FILTER_CONDITION_GENERAL_ID		NUMBER(10, 0)     NOT NULL,
	SURVEY_SID							NUMBER(10, 0)     NOT NULL,
	QS_FILTER_COND_GEN_TYPE_ID			NUMBER(10, 0)     NOT NULL,
    COMPARATOR							VARCHAR2(20),
    COMPARE_TO_STR_VAL					VARCHAR2(2047),
    COMPARE_TO_NUM_VAL					NUMBER(10, 0),
    CONSTRAINT PK_QS_FILTER_CONDITION_GENERAL PRIMARY KEY (CSRIMP_SESSION_ID, FILTER_ID, QS_FILTER_CONDITION_GENERAL_ID),
	CONSTRAINT FK_QS_FILTER_COND_GEN_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE,
	CONSTRAINT FK_QS_FILTER_COND_GEN_SURVEY FOREIGN KEY
    	(CSRIMP_SESSION_ID, SURVEY_SID) REFERENCES CSRIMP.QUICK_SURVEY (CSRIMP_SESSION_ID, SURVEY_SID)
    	ON DELETE CASCADE
);

ALTER TABLE CSR.QS_FILTER_CONDITION_GENERAL ADD CONSTRAINT FK_QS_FIL_COND_GEN_CHAIN_FIL 
	FOREIGN KEY (APP_SID, FILTER_ID) 
	REFERENCES CHAIN.FILTER(APP_SID, FILTER_ID) ON DELETE CASCADE;
	
CREATE INDEX csr.ix_qs_filter_cond_gen_survey ON csr.qs_filter_condition_general(app_sid, survey_sid);

GRANT INSERT ON csr.qs_filter_condition_general TO csrimp;
GRANT INSERT ON csr.qs_filter_cond_gen_type TO csrimp;
GRANT SELECT, INSERT, DELETE, UPDATE ON csrimp.qs_filter_cond_gen_type TO web_user;
GRANT SELECT, INSERT, DELETE, UPDATE ON csrimp.qs_filter_condition_general TO web_user;
GRANT SELECT, INSERT, DELETE, UPDATE ON chain.filter_value TO csr;
GRANT SELECT, INSERT, DELETE, UPDATE ON chain.filter_field TO csr;
GRANT EXECUTE ON chain.company_filter_pkg TO csr;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
        'QS_FILTER_CONDITION_GENERAL'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

-- extracts unanswered questions from quick survey responses
CREATE OR REPLACE VIEW csr.v$quick_survey_unans_quest AS
    SELECT qsr.app_sid, qsr.survey_sid, qsr.survey_response_id, qsq.question_id, qsq.pos AS question_pos, qsq.question_type, qsq.label AS question_label
	  FROM csr.v$quick_survey_response qsr
	  JOIN csr.quick_survey_question qsq ON qsq.app_sid = qsr.app_sid AND qsq.survey_sid = qsr.survey_sid
	 WHERE qsq.parent_id IS NULL
	   AND qsq.is_visible = 1
	   AND qsq.question_type NOT IN ('section', 'pagebreak', 'files', 'richtext')      
	   AND ( -- questions without nested answers
	    (qsq.question_type IN ('note', 'number', 'slider', 'date', 'regionpicker', 'radio')
		 AND (qsq.question_id IN (
		   SELECT question_id 
		     FROM csr.v$quick_survey_answer
		    WHERE app_sid = qsr.app_sid
		     AND survey_response_id = qsr.survey_response_id
			 AND (answer IS NULL AND question_option_id IS NULL AND val_number IS NULL AND region_sid IS NULL))))
		-- questions with nested answers
		OR (qsq.question_type = 'checkboxgroup'
		 AND NOT EXISTS ( -- consider as unanswered if none of the options are ticked
		   SELECT qsq1.question_id 
		     FROM csr.quick_survey_question qsq1, csr.v$quick_survey_answer qsa1           
		    WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id 
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.is_visible = 1
			  AND qsa1.val_number = 1))
		OR (qsq.question_type = 'matrix'
		 AND EXISTS ( -- consider as unanswered if any of the options/matrix-rows are not filled
		   SELECT qsq1.question_id 
		     FROM csr.quick_survey_question qsq1, csr.quick_survey_answer qsa1           
			WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.is_visible = 1
			  AND qsa1.question_option_id IS NULL))
		);
		
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (1, 'generalregionpicker', 'Region');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (2, 'generalsubmissiondate', 'Submission date');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (3, 'generalsubmissionuser', 'Submitted by');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (4, 'generalcontainscomments', 'Contains comments');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (5, 'generalscore', 'Score');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (6, 'generalcontainsunansweredquestions', 'Contains unanswered questions');

@..\quick_survey_pkg
@..\quick_survey_body
@..\chain\company_filter_pkg
@..\chain\company_filter_body
@update_tail