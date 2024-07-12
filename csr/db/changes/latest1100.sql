-- Please update version.sql too -- this keeps clean builds in sync
define version=1100
@update_header

CREATE TABLE CSR.QS_FILTER_BY_STATUS(
    APP_SID      NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_ID    NUMBER(10, 0)     NOT NULL,
    SURVEY_SID    NUMBER(10, 0)    NOT NULL,
    STATUS_ID    NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_QS_FILTER_BY_STATUS PRIMARY KEY (APP_SID, FILTER_ID, SURVEY_SID, STATUS_ID)
)
;

ALTER TABLE CSR.QS_FILTER_BY_STATUS ADD CONSTRAINT FK_FIL_BY_STAT_FIL
    FOREIGN KEY (APP_SID, FILTER_ID)
    REFERENCES CHAIN.FILTER (APP_SID, FILTER_ID) ON DELETE CASCADE;

ALTER TABLE CSR.QS_FILTER_BY_STATUS ADD CONSTRAINT FK_FIL_BY_STATUS_SURV 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES CSR.QUICK_SURVEY(APP_SID, SURVEY_SID) ON DELETE CASCADE
;

DROP TYPE CSR.T_QS_QUESTION_TABLE;

CREATE OR REPLACE TYPE CSR.T_QS_QUESTION_ROW AS
	OBJECT (
		QUESTION_ID				NUMBER(10),
		PARENT_ID				NUMBER(10),
		POS						NUMBER(10), 
		LABEL					VARCHAR2(4000), 
		QUESTION_TYPE			VARCHAR2(40), 
		SCORE					NUMBER(13,3),
		MAX_SCORE				NUMBER(13,3),
		UPLOAD_SCORE			NUMBER(13,3),
		LOOKUP_KEY				VARCHAR2(255),
		INVERT_SCORE			VARCHAR2(255),
		CUSTOM_QUESTION_TYPE_ID	NUMBER(10),
		WEIGHT					NUMBER(15,5)
	);
/
CREATE OR REPLACE TYPE CSR.T_QS_QUESTION_TABLE AS
  TABLE OF CSR.T_QS_QUESTION_ROW;
/

ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD(
    WEIGHT                     NUMBER(15, 5)     DEFAULT 1 NOT NULL
)
;

ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD(
    MAX_SCORE                NUMBER(13, 3)
)
;

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE ADD(
    OVERALL_SCORE            NUMBER(15, 5),
    OVERALL_MAX_SCORE        NUMBER(15, 5)
)
;

CREATE TABLE CSR.SCORE_THRESHOLD(
    APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCORE_THRESHOLD_ID     NUMBER(10, 0)     NOT NULL,
    MAX_VALUE              NUMBER(15, 5)     NOT NULL,
    DESCRIPTION            VARCHAR2(255)     NOT NULL,
    TEXT_COLOUR            NUMBER(10, 0)     NOT NULL,
    BACKGROUND_COLOUR      NUMBER(10, 0)     NOT NULL,
    ICON_IMAGE             BLOB,
    ICON_IMAGE_FILENAME    VARCHAR2(255),
    ICON_IMAGE_MIME_TYPE    VARCHAR2(255),
    CONSTRAINT PK_SCORE_THRESHOLD PRIMARY KEY (APP_SID, SCORE_THRESHOLD_ID)
)
;

ALTER TABLE CSR.QUICK_SURVEY_ANSWER MODIFY SCORE NUMBER(15,5);
ALTER TABLE CSR.QUICK_SURVEY_ANSWER MODIFY MAX_SCORE NUMBER(15,5);

CREATE UNIQUE INDEX CSR.UK_SCORE_THRESH_MAX_SCORE ON CSR.SCORE_THRESHOLD(APP_SID, MAX_VALUE)
;

ALTER TABLE CSR.SUPPLIER ADD(
    SCORE                 NUMBER(15, 5),
    SCORE_LAST_CHANGED    DATE,
    SCORE_THRESHOLD_ID    NUMBER(10, 0)
);

ALTER TABLE CSR.SCORE_THRESHOLD ADD CONSTRAINT FK_SCORE_THRESH_APP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.SUPPLIER ADD CONSTRAINT FK_SUPPLIER_THRESHOLD 
    FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
    REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID)
;

CREATE SEQUENCE CSR.SCORE_THRESHOLD_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_RESPONSE_REGION
(
	RESPONSE_ID			NUMBER(10)	NOT NULL,
	REGION_SID			NUMBER(10)	NOT NULL,
	PERIOD_START_DTM	DATE		NOT NULL,
	PERIOD_END_DTM		DATE		NOT NULL,
	CONSTRAINT PK_TEMP_RESPONSE_REGION PRIMARY KEY (RESPONSE_ID)
) ON COMMIT DELETE ROWS;

grant select on chain.v$questionnaire_share to csr;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'SCORE_THRESHOLD'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
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
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

-- Produced by chain.card_pkg.dumpcard
DECLARE
v_card_id         chain.card.card_id%TYPE;
v_desc            chain.card.description%TYPE;
v_class           chain.card.class_type%TYPE;
v_js_path         chain.card.js_include%TYPE;
v_js_class        chain.card.js_class_type%TYPE;
v_css_path        chain.card.css_include%TYPE;
v_actions         chain.T_STRING_LIST;
BEGIN
-- Chain.Cards.CsrSupplierExtras
v_desc := 'Extra details for the given supplier';
v_class := 'Credit360.Chain.Cards.CsrSupplierExtras';
v_js_path := '/csr/site/chain/cards/csrSupplierExtras.js';
v_js_class := 'Chain.Cards.CsrSupplierExtras';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
END;
/

-- Extracted from quick_survey_body
CREATE PROCEDURE CSR.XPJ_TEMP_CalculateScore(
	in_response_id				IN	csr.quick_survey_response.survey_response_id%TYPE,
	in_question_id				IN	csr.quick_survey_question.question_id%TYPE,
	out_score					OUT	csr.quick_survey_answer.score%TYPE,
	out_max_score				OUT	csr.quick_survey_answer.max_score%TYPE
)
AS
	v_temp_score			quick_survey_answer.score%TYPE;
	v_temp_max_score		quick_survey_answer.max_score%TYPE;
	v_question_type			quick_survey_question.question_type%TYPE;
BEGIN
	SELECT question_type
	  INTO v_question_type
	  FROM csr.quick_survey_question
	 WHERE question_id = in_question_id;
	
	IF v_question_type='section' THEN
		FOR r IN (
			SELECT question_id, weight
			  FROM csr.quick_survey_question
			 WHERE parent_id = in_question_id
		) LOOP
			CSR.XPJ_TEMP_CalculateScore(in_response_id, r.question_id, v_temp_score, v_temp_max_score);
			
			-- TODO: Weighting here
			out_score := CASE WHEN out_score IS NULL AND v_temp_score IS NULL THEN NULL ELSE NVL(out_score, 0) + (r.weight*NVL(v_temp_score, 0)) END;
			out_max_score := CASE WHEN out_max_score IS NULL AND v_temp_max_score IS NULL THEN NULL ELSE NVL(out_max_score, 0) +(r.weight* NVL(v_temp_max_score, 0)) END;
			
		END LOOP;
		
		IF out_max_score IS NULL THEN
			-- XXX: Would it be better to remove this row altogether?
			UPDATE csr.quick_survey_answer
			   SET score = NULL,
					max_score = NULL
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id;
		ELSE
			
			out_score := out_score / out_max_score;
			out_max_score := out_max_score / out_max_score;
			
			BEGIN
				INSERT INTO quick_survey_answer(question_id, survey_response_id, score, max_score)
				VALUES (in_question_id, in_response_id, out_score, out_max_score);
			EXCEPTION WHEN dup_val_on_index THEN
				UPDATE csr.quick_survey_answer
				   SET score = out_score,
						max_score = out_max_score
				 WHERE survey_response_id = in_response_id
				   AND question_id = in_question_id;
			END;
		END IF;
	ELSE
		BEGIN
			SELECT score, max_score
			  INTO out_score, out_max_score
			  FROM csr.quick_survey_answer
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id;
			
			out_score := out_score / out_max_score;
			out_max_score := out_max_score / out_max_score;
			
		EXCEPTION WHEN no_data_found THEN
			NULL;
		END;
	END IF;
END;
/

CREATE PROCEDURE CSR.XPJ_TEMP_CalcResponseScore(
	in_response_id				IN	csr.quick_survey_response.survey_response_id%TYPE,
	out_score					OUT	csr.quick_survey_answer.score%TYPE,
	out_max_score				OUT	csr.quick_survey_answer.max_score%TYPE
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	v_temp_score			quick_survey_answer.score%TYPE;
	v_temp_max_score		quick_survey_answer.max_score%TYPE;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM csr.quick_survey_response
	 WHERE survey_response_id = in_response_id;
	
	FOR r IN (
		SELECT question_id, weight
		  FROM csr.quick_survey_question
		 WHERE survey_sid = v_survey_sid
		   AND parent_id IS NULL
	) LOOP
		CSR.XPJ_TEMP_CalculateScore(in_response_id, r.question_id, v_temp_score, v_temp_max_score);
		
		-- TODO: Weighting here
		out_score := CASE WHEN out_score IS NULL AND v_temp_score IS NULL THEN NULL ELSE NVL(out_score, 0) + (r.weight*NVL(v_temp_score, 0)) END;
		out_max_score := CASE WHEN out_max_score IS NULL AND v_temp_max_score IS NULL THEN NULL ELSE NVL(out_max_score, 0) +(r.weight*NVL(v_temp_max_score, 0)) END;
		
	END LOOP;
	
	out_score := out_score / out_max_score;
	out_max_score := out_max_score / out_max_score;
	
	UPDATE csr.quick_survey_response
	   SET overall_score = out_score,
			overall_max_score = out_max_score
	 WHERE survey_response_id = in_response_id;
END;
/

DECLARE
	v_temp number(15,5);
	v_temp2 number(15,5);
BEGIN
	FOR h IN (
		SELECT host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT DISTINCT app_sid
			  FROM csr.quick_survey_response
		)
	) LOOP
		
		security.user_pkg.logonadmin(h.host);
		
		FOR r IN (
			SELECT survey_response_id
			  FROM csr.quick_survey_response
		) LOOP
			CSR.XPJ_TEMP_CalcResponseScore(r.survey_response_id, v_temp, v_temp2);
		END LOOP;
	END LOOP;
END;
/

BEGIN
	security.user_pkg.logonadmin;
	FOR h IN (
		SELECT host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT DISTINCT app_sid
			  FROM csr.aggregate_ind_group
			 WHERE helper_proc like 'csr.quick_survey_pkg.%'
		)
	) LOOP
		security.user_pkg.logonadmin(h.host);
		FOR r IN (
			SELECT aggregate_ind_group_id
			  FROM csr.aggregate_ind_group
			 WHERE helper_proc like 'csr.quick_survey_pkg.%'
		) LOOP
			csr.calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id, TO_DATE('01-JAN-1990', 'dd-MON-yyyy'), TO_DATE('01-JAN-2020', 'dd-MON-yyyy'));
		END LOOP;
	END LOOP;
END;
/

DROP PROCEDURE CSR.XPJ_TEMP_CalcResponseScore;
DROP PROCEDURE CSR.XPJ_TEMP_CalculateScore;

@..\chain\chain_pkg
@..\quick_survey_pkg
@..\supplier_pkg
@..\chain\company_pkg
@..\chain\helper_pkg


@..\quick_survey_body
@..\supplier_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\helper_body

@update_tail
