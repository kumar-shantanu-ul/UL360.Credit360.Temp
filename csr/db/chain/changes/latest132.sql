define version=132
@update_header

DELETE FROM chain.FILTER;
DELETE FROM chain.COMPOUND_FILTER;
COMMIT;

ALTER TABLE chain.COMPOUND_FILTER ADD (
	CARD_GROUP_ID          NUMBER(10, 0)    NOT NULL
);

ALTER TABLE chain.COMPOUND_FILTER ADD CONSTRAINT FK_CMP_FIL_CARD_GRP 
    FOREIGN KEY (CARD_GROUP_ID)
    REFERENCES chain.CARD_GROUP(CARD_GROUP_ID)
;

ALTER TABLE chain.COMPOUND_FILTER DROP CONSTRAINT FK_CMP_FIL_USER_SID;

ALTER TABLE chain.COMPOUND_FILTER ADD CONSTRAINT FK_CMP_FIL_USER_SID 
    FOREIGN KEY (APP_SID, CREATED_BY_USER_SID)
    REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
;

@..\filter_pkg
@..\company_filter_pkg
@..\filter_body
@..\company_filter_body


DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.Filters.SurveyQuestionnaire
	v_desc := 'Dummy Survey Filter';
	v_class := 'Credit360.QuickSurvey.Cards.SurveyResultsFilter';
	v_js_path := '/csr/site/QuickSurvey/results/surveyResultsFilter.js';
	v_js_class := 'QuickSurvey.Cards.SurveyResultsFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
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
		EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
END;
/

DECLARE
	v_card_id		chain.card.card_id%TYPE;
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('QuickSurvey.Cards.SurveyResultsFilter');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			filter_type_id_seq.NEXTVAL,
			'Survey Questionnaire Filter',
			'csr.quick_survey_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE chain.filter_type
			   SET description = 'Survey Questionnaire Filter',
			       helper_pkg = 'csr.quick_survey_pkg'
			 WHERE card_id = v_card_id;
	END;
END;
/

BEGIN
	INSERT INTO chain.card_group(card_group_id, name, description)
	VALUES(24, 'Simple Survey Filter', 'Allows filtering of survey responses');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE chain.card_group
		   SET description='Allows filtering of survey responses'
		 WHERE card_group_id=24;
END;
/

-- Add a card group for each customer with at least 1 survey
DECLARE
	v_card_group_id			chain.card_group.card_group_id%TYPE DEFAULT 24;
	v_position				NUMBER(10) DEFAULT 1;
BEGIN
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.quick_survey
	) LOOP
		DBMS_OUTPUT.put_line(r.app_sid);
		BEGIN
			-- cards are in chain at the moment so need a row in this table - ugly
			INSERT INTO chain.customer_options(app_sid)
			VALUES (r.app_sid);
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
		
		DELETE FROM chain.card_group_progression
		 WHERE app_sid = r.app_sid
		   AND card_group_id = v_card_group_id;
		
		DELETE FROM chain.card_group_card
		 WHERE app_sid = r.app_sid
		   AND card_group_id = v_card_group_id;
		
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set,
					invert_capability_check, force_terminate, required_capability_id)
		SELECT r.app_sid, v_card_group_id, card_id, v_position, NULL, 0, 0, NULL
		  FROM chain.card
		 WHERE js_class_type = 'QuickSurvey.Cards.SurveyResultsFilter';
		
	END LOOP;
END;
/

grant select, references on chain.v$company to csr;
grant select on chain.filter_type to csr;

connect csr/csr@&_CONNECT_IDENTIFIER

@..\..\quick_survey_pkg
@..\..\quick_survey_body

connect chain/chain@&_CONNECT_IDENTIFIER

@update_tail
