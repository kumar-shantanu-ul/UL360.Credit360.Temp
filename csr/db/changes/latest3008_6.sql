-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- dummy packages
CREATE OR REPLACE PACKAGE csr.region_report_pkg AS
END;
/

GRANT EXECUTE ON csr.region_report_pkg TO web_user;
GRANT EXECUTE ON csr.region_report_pkg TO chain;

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
	v_desc := 'Region Filter';
	v_class := 'Credit360.Schema.Cards.RegionFilter';
	v_js_path := '/csr/site/schema/indRegion/list/filters/RegionFilter.js';
	v_js_class := 'Credit360.Region.Filters.RegionFilter';
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
		VALUES (51, 'Region Filter', 'Allows filtering of regions', 'csr.region_report_pkg', '/csr/site/schema/indRegion/list/List.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Region.Filters.RegionFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Region Filter', 'csr.region_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.customer
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 51, v_card_id, 0);
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (51, 1, 'Number of regions');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (51, 1, 1, 'Region');
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@@../chain/filter_pkg
@@../region_report_pkg
@@../region_report_body

@update_tail
