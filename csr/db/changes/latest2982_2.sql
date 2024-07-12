-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE csr.qs_filter_condition_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE SEQUENCE csr.qs_filter_condition_gen_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE GLOBAL TEMPORARY TABLE csr.temp_filter_conditions (
	survey_sid						NUMBER(10) NOT NULL,
	qs_campaign_sid					NUMBER(10)
) ON COMMIT DELETE ROWS;

-- Alter tables
ALTER TABLE csr.qs_filter_condition ADD (
	qs_campaign_sid					NUMBER(10),
	CONSTRAINT fk_qs_filter_conditn_campaign FOREIGN KEY (app_sid, qs_campaign_sid)
		REFERENCES csr.qs_campaign (app_sid, qs_campaign_sid)
);

ALTER TABLE csr.qs_filter_condition_general ADD (
	qs_campaign_sid					NUMBER(10),
	CONSTRAINT fk_qs_fltr_condtn_gen_campaign FOREIGN KEY (app_sid, qs_campaign_sid)
		REFERENCES csr.qs_campaign (app_sid, qs_campaign_sid)
);

ALTER TABLE csr.qs_filter_condition RENAME COLUMN qs_filter_condition_id TO pos;

ALTER TABLE csr.qs_filter_condition ADD (
	qs_filter_condition_id			NUMBER(10),
	survey_sid						NUMBER(10),
	CONSTRAINT fk_qs_filter_condition_survey FOREIGN KEY (app_sid, survey_sid)
		REFERENCES csr.quick_survey (app_sid, survey_sid)
);

UPDATE csr.qs_filter_condition
   SET qs_filter_condition_id = csr.qs_filter_condition_id_seq.NEXTVAL
 WHERE qs_filter_condition_id IS NULL;
 
ALTER TABLE csr.qs_filter_condition MODIFY qs_filter_condition_id NOT NULL;

UPDATE csr.qs_filter_condition qfc
   SET survey_sid = (
	SELECT survey_sid
	  FROM csr.quick_survey_question qsq
	 WHERE qsq.app_sid = qfc.app_sid
	   AND qsq.question_id = qfc.question_id
	   AND qsq.survey_version = qfc.survey_version
	)
 WHERE survey_sid IS NULL; 
 
ALTER TABLE csr.qs_filter_condition MODIFY survey_sid NOT NULL;

ALTER TABLE csr.qs_filter_condition DROP CONSTRAINT pk_qs_filter_condition DROP INDEX;
ALTER TABLE csr.qs_filter_condition ADD CONSTRAINT pk_qs_filter_condition PRIMARY KEY (app_sid, qs_filter_condition_id);

CREATE UNIQUE INDEX csr.uk_qs_filter_condition ON csr.qs_filter_condition (app_sid, filter_id, pos, NVL(qs_campaign_sid, survey_sid));

ALTER TABLE csr.qs_filter_condition_general RENAME COLUMN qs_filter_condition_general_id TO pos;

ALTER TABLE csr.qs_filter_condition_general ADD (
	qs_filter_condition_general_id	NUMBER(10)
);

UPDATE csr.qs_filter_condition_general
   SET qs_filter_condition_general_id = csr.qs_filter_condition_gen_id_seq.NEXTVAL
 WHERE qs_filter_condition_general_id IS NULL;
 
ALTER TABLE csr.qs_filter_condition_general MODIFY qs_filter_condition_general_id NOT NULL;

ALTER TABLE csr.qs_filter_condition_general DROP CONSTRAINT pk_qs_filter_condition_general DROP INDEX;
ALTER TABLE csr.qs_filter_condition_general ADD CONSTRAINT pk_qs_filter_condition_general PRIMARY KEY (app_sid, qs_filter_condition_general_id);

CREATE UNIQUE INDEX csr.uk_qs_filter_condition_general ON csr.qs_filter_condition_general (app_sid, filter_id, pos, NVL(qs_campaign_sid, survey_sid));


ALTER TABLE csrimp.qs_filter_condition RENAME COLUMN qs_filter_condition_id TO pos;
ALTER TABLE csrimp.qs_filter_condition ADD (
	qs_filter_condition_id			NUMBER(10),
	survey_sid						NUMBER(10),
	qs_campaign_sid					NUMBER(10)
);

UPDATE csrimp.qs_filter_condition
   SET qs_filter_condition_id = csr.qs_filter_condition_id_seq.NEXTVAL
 WHERE qs_filter_condition_id IS NULL;
 
ALTER TABLE csrimp.qs_filter_condition MODIFY qs_filter_condition_id NOT NULL;

UPDATE csrimp.qs_filter_condition qfc
   SET survey_sid = (
	SELECT survey_sid
	  FROM csrimp.quick_survey_question qsq
	 WHERE qsq.csrimp_session_id = qfc.csrimp_session_id
	   AND qsq.question_id = qfc.question_id
	   AND qsq.survey_version = qfc.survey_version
	)
 WHERE survey_sid IS NULL; 
 
ALTER TABLE csrimp.qs_filter_condition MODIFY survey_sid NOT NULL;

ALTER TABLE csrimp.qs_filter_condition DROP CONSTRAINT pk_qs_filter_condition DROP INDEX;
ALTER TABLE csrimp.qs_filter_condition ADD CONSTRAINT pk_qs_filter_condition PRIMARY KEY (csrimp_session_id, qs_filter_condition_id);

CREATE UNIQUE INDEX csrimp.uk_qs_filter_condition ON csrimp.qs_filter_condition (csrimp_session_id, filter_id, pos, NVL(qs_campaign_sid, survey_sid));


ALTER TABLE csrimp.qs_filter_condition_general RENAME COLUMN qs_filter_condition_general_id TO pos;

ALTER TABLE csrimp.qs_filter_condition_general ADD (
	qs_filter_condition_general_id	NUMBER(10),	
	qs_campaign_sid					NUMBER(10)
);

UPDATE csrimp.qs_filter_condition_general
   SET qs_filter_condition_general_id = csr.qs_filter_condition_gen_id_seq.NEXTVAL
 WHERE qs_filter_condition_general_id IS NULL;
 
ALTER TABLE csrimp.qs_filter_condition_general MODIFY qs_filter_condition_general_id NOT NULL;

ALTER TABLE csrimp.qs_filter_condition_general DROP CONSTRAINT pk_qs_filter_condition_general DROP INDEX;
ALTER TABLE csrimp.qs_filter_condition_general ADD CONSTRAINT pk_qs_filter_condition_general PRIMARY KEY (csrimp_session_id, qs_filter_condition_general_id);

CREATE UNIQUE INDEX csrimp.uk_qs_filter_condition_general ON csrimp.qs_filter_condition_general (csrimp_session_id, filter_id, pos, NVL(qs_campaign_sid, survey_sid));

-- fk indexes
create index csr.ix_qs_filter_con_survey_sid on csr.qs_filter_condition (app_sid, survey_sid);
create index csr.ix_qs_filter_con_qs_campaign_s on csr.qs_filter_condition (app_sid, qs_campaign_sid);
create index csr.ix_qs_filter_con_gen_campaign on csr.qs_filter_condition_general (app_sid, qs_campaign_sid);

-- *** Grants ***
GRANT SELECT ON csr.qs_filter_condition_id_seq TO CSRIMP;
GRANT SELECT ON csr.qs_filter_condition_gen_id_seq TO CSRIMP;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.Filters.CompanyRelationshipFilter
	v_desc := 'Survey Campaign Filter';
	v_class := 'Credit360.Chain.Cards.Filters.SurveyCampaign';
	v_js_path := '/csr/site/chain/cards/filters/surveyCampaign.js';
	v_js_class := 'Chain.Cards.Filters.SurveyCampaign';
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

DECLARE
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.SurveyCampaign');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Survey Campaign Filter',
			'csr.quick_survey_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Basic Company Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/

/* US3032 */
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.Filters.CompanyRelationshipFilter
	v_desc := 'Survey Response Filter';
	v_class := 'Credit360.Audit.Cards.SurveyResponse';
	v_js_path := '/csr/site/audit/surveyResponse.js';
	v_js_class := 'Credit360.Audit.Filters.SurveyResponse';
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

DECLARE
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Credit360.Audit.Filters.SurveyResponse');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Survey Response Filter',
			'csr.quick_survey_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Internal Audit Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Internal Audit Filter');
	END;	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../quick_survey_pkg
@../csrimp/imp_pkg

@../chain/setup_body
@../csrimp/imp_body
@../campaign_body
@../quick_survey_body
@../schema_body

@update_tail
