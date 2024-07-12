-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=28
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
	v_card_id			chain.card.card_id%TYPE;
	v_desc				chain.card.description%TYPE;
	v_class				chain.card.class_type%TYPE;
	v_js_path			chain.card.js_include%TYPE;
	v_js_class			chain.card.js_class_type%TYPE;
	v_css_path			chain.card.css_include%TYPE;
	v_actions			chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Metric Value Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductMetricValFilter';
	v_js_path := '/csr/site/chain/cards/filters/productMetricValFilter.js';
	v_js_class := 'Chain.Cards.Filters.ProductMetricValFilter';
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
		VALUES(62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 'Product Metric Value Filter', 'Allows filtering of product metric values.', 'chain.product_metric_report_pkg', '/csr/site/chain/products/productMetricValList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductMetricValFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Metric Value Filter', 'chain.product_metric_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT app_sid FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
					VALUES (r.app_sid, 62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, v_card_id, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 1 /*chain.product_metric_report_pkg.AGG_TYPE_COUNT_METRIC_VAL*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 2 /*chain.product_metric_report_pkg.AGG_TYPE_SUM_METRIC_VAL*/, 'Sum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 3 /*chain.product_metric_report_pkg.AGG_TYPE_AVG_METRIC_VAL*/, 'Average of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 4 /*chain.product_metric_report_pkg.AGG_TYPE_MAX_METRIC_VAL*/, 'Maximum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (62 /*chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL*/, 5 /*chain.product_metric_report_pkg.AGG_TYPE_MIN_METRIC_VAL*/, 'Minimum of metric values');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 19, 'Product Metric', '/csr/site/chain/manageProduct/controls/ProductMetricValTab.js', 'Chain.ManageProduct.ProductMetricValTab', 'Credit360.Chain.Plugins.ProductMetricValPlugin', 'Product Metric tab.');

-- ** New package grants **
CREATE OR REPLACE PACKAGE chain.product_metric_report_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.product_metric_report_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/

GRANT EXECUTE ON chain.product_metric_report_pkg TO cms;
GRANT EXECUTE ON chain.product_metric_pkg TO csr;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/filter_pkg
@../chain/product_metric_report_pkg

@../chain/company_product_body
@../chain/plugin_body
@../chain/product_metric_report_body
@../enable_body

@update_tail
