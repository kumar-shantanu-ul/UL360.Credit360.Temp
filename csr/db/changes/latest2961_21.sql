-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=21
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
	v_desc := 'Meter Filter';
	v_class := 'Credit360.Metering.Cards.MeterFilter';
	v_js_path := '/csr/site/meter/filters/MeterFilter.js';
	v_js_class := 'Credit360.Metering.Filters.MeterFilter';
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
	security.user_pkg.LogonAdmin;

	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(50, 'Meter Filter', 'Allows filtering of meters', 'csr.meter_list_pkg', '/csr/site/meter/meterList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Metering.Filters.MeterFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Meter Filter', 'csr.meter_list_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with initiatives
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.meter_source_type
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 50, v_card_id, 0);
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
		 VALUES (50, 1, 'Number of meters');
		 
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	     VALUES (50, 1, 1, 'Meter region');
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.meter_list_pkg AS END;
/
GRANT EXECUTE ON csr.meter_list_pkg TO web_user;
GRANT EXECUTE ON csr.meter_list_pkg TO chain;

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_list_pkg
@../meter_pkg
@../chain/filter_pkg
@../region_metric_pkg
@../tag_pkg

@../enable_body
@../meter_list_body
@../meter_body
@../property_report_body
@../region_metric_body
@../tag_body

@update_tail
