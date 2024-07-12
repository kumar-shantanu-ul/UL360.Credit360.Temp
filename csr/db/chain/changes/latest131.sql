define version=131
@update_header

@requiredvers 'csr' 744 ''

ALTER TABLE chain.FILTER ADD(
    OPERATOR_TYPE          VARCHAR2(8)      DEFAULT 'and' NOT NULL,
    CONSTRAINT CHK_FILTER_OP_TYPE CHECK (OPERATOR_TYPE in ('and','or'))
);


-- from exec card_pkg.dumpcard('Chain.Cards.Filters.SurveyQuestionnaire');
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
	v_desc := 'Survey Questionnaire Filter';
	v_class := 'Credit360.Chain.Cards.Filters.SurveyQuestionnaire';
	v_js_path := '/csr/site/chain/cards/filters/surveyQuestionnaire.js';
	v_js_class := 'Chain.Cards.Filters.SurveyQuestionnaire';
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
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.SurveyQuestionnaire');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
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

grant select, references on chain.filter to csr;
grant execute on chain.filter_pkg to csr;

@..\filter_pkg
@..\filter_body
@..\helper_body

grant select, references on chain.v$company to csr;

connect csr/csr@&_CONNECT_IDENTIFIER

ALTER TABLE csr.QS_FILTER_CONDITION ADD CONSTRAINT FK_QS_FIL_COND_CHAIN_FIL
    FOREIGN KEY (APP_SID, FILTER_ID)
    REFERENCES CHAIN.FILTER(APP_SID, FILTER_ID) ON DELETE CASCADE;

@..\..\quick_survey_pkg
@..\..\quick_survey_body

grant execute on csr.quick_survey_pkg to chain;

connect chain/chain@&_CONNECT_IDENTIFIER

@update_tail
