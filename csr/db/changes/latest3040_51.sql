-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=51
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
	v_card_id		chain.card.card_id%TYPE;
	v_desc			chain.card.description%TYPE;
	v_class			chain.card.class_type%TYPE;
	v_js_path		chain.card.js_include%TYPE;
	v_js_class		chain.card.js_class_type%TYPE;
	v_css_path		chain.card.css_include%TYPE;
	v_actions		chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductFilter';
	v_js_path := '/csr/site/chain/cards/filters/productFilter.js';
	v_js_class := 'Credit360.Chain.Filters.ProductFilter';
	v_css_path := '';

	security.user_pkg.logonadmin('');

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

	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES (56, v_desc, 'Allows filtering of products', 'chain.product_report_pkg', '/csr/site/chain/products/productList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, v_desc , 'chain.product_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.customer
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 56, v_card_id, 0);
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (56, 1, 'Number of products');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (56, 2, 2, 'Last edited');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg
@../chain/product_report_pkg
@../chain/filter_pkg
@../chain/product_type_pkg
@../chain/product_pkg

@../chain/company_product_body
@../chain/product_report_body
@../chain/product_type_body
@../chain/product_body

@update_tail
