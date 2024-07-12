-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=11
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

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Activity Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ActivityFilter';
	v_js_path := '/csr/site/chain/cards/filters/activityFilter.js';
	v_js_class := 'Chain.Cards.Filters.ActivityFilter';
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
	

	v_desc := 'Activity Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ActivityFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/activityFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ActivityFilterAdapter';
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
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 'Activity Filter', 'Allows filtering of activities', 'chain.activity_report_pkg', '/csr/site/chain/activities/activityList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ActivityFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Activity Filter', 'chain.activity_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with chain
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, v_card_id, 0);
	END LOOP;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ActivityFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Activity Filter Adapter', 'chain.activity_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	

	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, v_card_id, 0);
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 1 /*chain.activity_report_pkg.AGG_TYPE_COUNT*/, 'Number of activities');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 1 /*chain.activity_report_pkg.COL_TYPE_SUPPLIER_REGION*/, 1 /*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Supplier region');
	
	INSERT INTO chain.grid_extension (grid_extension_id, base_card_group_id, extension_card_group_id, record_name) 
	VALUES (4, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, 'company');
END;
/


-- ** New package grants **

create or replace package chain.activity_report_pkg as
procedure dummy;
end;
/
create or replace package body chain.activity_report_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on chain.activity_report_pkg to web_user;
-- *** Conditional Packages ***

-- *** Packages ***
@../chain/activity_report_pkg
@../chain/company_filter_pkg
@../chain/company_user_pkg
@../chain/filter_pkg

@../chain/activity_report_body
@../chain/company_filter_body
@../chain/company_user_body
@../chain/filter_body

@update_tail
