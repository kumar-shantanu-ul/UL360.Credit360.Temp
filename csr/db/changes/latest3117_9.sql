-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=9
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
	v_desc := 'Product Supplier Product Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierProductFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierProductFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierProductFilterAdapter';
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
	   AND action <> 'default';
	
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
	
	v_desc := 'Product Metric Value Product Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductMetricValProductFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productMetricValProductFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductMetricValProductFilterAdapter';
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
	   AND action <> 'default';
	
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
	
	v_desc := 'Product Supplier Metric Value Product Supplier Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierMetricValProductSupplierFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter';
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
	   AND action <> 'default';
	
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
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierProductFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Product Filter Adapter', 'chain.product_supplier_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductMetricValProductFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Metric Value Product Filter Adapter', 'chain.product_metric_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 62
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 62, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Metric Value Product Supplier Filter Adapter', 'chain.prdct_supp_mtrc_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 63
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 63, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/

DECLARE
	v_card_id	NUMBER(10);
BEGIN	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CompanyProductFilterAdapter';
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, v_card_id, r.pos, NULL, NULL);
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
@../chain/product_supplier_report_pkg
@../chain/product_metric_report_pkg
@../chain/prdct_supp_mtrc_report_pkg

@../chain/product_supplier_report_body
@../chain/product_metric_report_body
@../chain/prdct_supp_mtrc_report_body

@update_tail
