-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=19
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
  v_card_id NUMBER;
BEGIN
  -- Remove previous incarnation of a product filter. Only used by bdchain.credit360.com.
  SELECT card_id 
    INTO v_card_id
    FROM CHAIN.FILTER_TYPE
   WHERE description = 'Chain Company Product Filter';

  DELETE FROM chain.filter_type WHERE card_id = v_card_id;
  DELETE FROM chain.card_progression_action WHERE card_id = v_card_id;
  DELETE FROM chain.card_group_card WHERE card_id = v_card_id;
  DELETE FROM chain.card WHERE card_id = v_card_id;
END;
/

UPDATE chain.card
   SET js_class_type = 'Chain.Cards.Filters.ProductFilter'
 WHERE js_class_type = 'Credit360.Chain.Filters.ProductFilter';

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductFilterAdapter';
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
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Company Product Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.CompanyProductFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/companyProductFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.CompanyProductFilterAdapter';
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
	v_products_capability_id		NUMBER(10);
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CompanyProductFilterAdapter';

	SELECT capability_id
	  INTO v_products_capability_id
	  FROM chain.capability 
	 WHERE capability_name = 'Products' AND capability_type_id = 1;
	 
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Company Product Filter Adapter', 'chain.company_filter_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	FOR r IN (
		SELECT DISTINCT cgc.app_sid, NVL(MAX(cgc.position) + 1, 1) pos
		  FROM chain.card_group_card cgc
		  JOIN chain.customer_options co ON co.app_sid = cgc.app_sid
		 WHERE cgc.card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		   AND co.enable_product_compliance = 1
		 GROUP BY cgc.app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
				 VALUES (r.app_sid, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, v_card_id, r.pos);
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
@../chain/product_report_pkg
@../chain/setup_pkg

@../chain/company_filter_body
@../chain/product_report_body
@../chain/setup_body


@update_tail
