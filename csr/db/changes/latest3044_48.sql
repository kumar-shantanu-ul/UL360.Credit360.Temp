-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=48
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;
END;
/

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Survey Response Filter';
	v_class := 'Credit360.QuickSurvey.Cards.SurveyResponseFilter';
	v_js_path := '/csr/site/quicksurvey/filters/surveyResponseFilter.js';
	v_js_class := 'Credit360.QuickSurvey.Filters.SurveyResponseFilter';
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

	v_desc := 'Survey Response Audit Filter Adapter';
	v_class := 'Credit360.QuickSurvey.Cards.SurveyResponseAuditFilterAdapter';
	v_js_path := '/csr/site/quicksurvey/filters/surveyResponseAuditFilterAdapter.js';
	v_js_class := 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter';
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
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 'Survey Response Filter', 'Allows filtering of survey responses', 'csr.quick_survey_report_pkg', '/csr/site/quickSurvey/responseList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.QuickSurvey.Filters.SurveyResponseFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Survey Response Filter', 'csr.quick_survey_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	SELECT card_id
	  INTO v_audit_filter_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Survey Response Audit Filter Adapter', 'csr.quick_survey_report_pkg', v_audit_filter_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	FOR r IN (
		SELECT app_sid FROM csr.customer
	) LOOP
		BEGIN
			v_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, r.app_sid, 'wwwroot/surveys');
				
			BEGIN
				INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
						VALUES (r.app_sid, 54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, v_card_id, 0);
				EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
			END;
			
			v_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, r.app_sid, 'Audits');
				
			BEGIN
				INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
						VALUES (r.app_sid, 54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, v_audit_filter_card_id, 1);
				EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Not a survey-enabled site, or not an audit-enabled site
		END;
	END LOOP;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 1 /*csr.quick_survey_report_pkg.AGG_TYPE_COUNT*/, 'Number of survey responses');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 2 /*csr.quick_survey_report_pkg.AGG_TYPE_SUM_SCORES*/, 'Sum of survey response scores');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 3 /*csr.quick_survey_report_pkg.AGG_TYPE_AVG_SCORE*/, 'Average survey response score');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 4 /*csr.quick_survey_report_pkg.AGG_TYPE_MAX_SCORE*/, 'Maximum survey response score');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 5 /*csr.quick_survey_report_pkg.AGG_TYPE_MIN_SCORE*/, 'Minimum of survey response score');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		VALUES (54 /*chain.filter_pkg.FILTER_TYPE_QS_RESPONSES*/, 1 /*chain.quick_survey_report_pkg.COL_TYPE_REGION_SID*/, 1 /*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Survey response region');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.quick_survey_report_pkg AS END;
/

GRANT EXECUTE ON csr.quick_survey_report_pkg TO chain;
GRANT EXECUTE ON csr.quick_survey_report_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../quick_survey_report_pkg

@../enable_body
@../quick_survey_report_body

@update_tail
