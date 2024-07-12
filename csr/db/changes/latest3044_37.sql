-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CMS.TAB ADD SHOW_IN_PRODUCT_FILTER NUMBER(1) DEFAULT 0;
UPDATE CMS.TAB SET SHOW_IN_PRODUCT_FILTER = 0 WHERE SHOW_IN_PRODUCT_FILTER IS NULL;
ALTER TABLE CMS.TAB MODIFY SHOW_IN_PRODUCT_FILTER NOT NULL;
ALTER TABLE CMS.TAB ADD CONSTRAINT CHK_SHOW_IN_PRODUCT_FILTER CHECK (SHOW_IN_PRODUCT_FILTER IN (0,1));

ALTER TABLE CSRIMP.CMS_TAB ADD SHOW_IN_PRODUCT_FILTER NUMBER(1) NULL;
UPDATE CSRIMP.CMS_TAB SET SHOW_IN_PRODUCT_FILTER = 0 WHERE SHOW_IN_PRODUCT_FILTER IS NULL;
ALTER TABLE CSRIMP.CMS_TAB MODIFY SHOW_IN_PRODUCT_FILTER NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

insert into cms.col_type (col_type, description) values (39, 'Product');

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_product_filter_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
	v_product_filter_card_id         chain.card.card_id%TYPE;
BEGIN
	-- Chain.Cards.Filters.CompanyCmsFilterAdapter
	v_desc := 'Chain Product CMS Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductCmsFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productCmsFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductCmsFilterAdapter';
	v_css_path := '';

	v_product_filter_js_class := 'Credit360.Chain.Filters.ProductFilter';

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

	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'Chain Product CMS Filter',
				'chain.product_report_pkg',
				v_card_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'Chain Product CMS Filter',
					   helper_pkg = 'chain.product_report_pkg'
				 WHERE card_id = v_card_id;
	END;

	SELECT card_id
	  INTO v_product_filter_card_id
	  FROM chain.card
	 WHERE js_class_type = v_product_filter_js_class;

	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT c.app_sid, host 
		  FROM csr.customer c
		  JOIN chain.customer_options co on co.app_sid = c.app_sid
		 WHERE co.enable_product_compliance = 1
	) LOOP
		security.user_pkg.logonadmin(r.host);
		DELETE FROM chain.card_group_card
		 WHERE card_group_id = 56;
		
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 56, v_product_filter_card_id, 0);
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 56, v_card_id, 1);

--		chain.card_pkg.SetGroupCards('Product Filter', chain.T_STRING_LIST('Credit360.Chain.Filters.ProductFilter', 'Chain.Cards.Filters.ProductCmsFilterAdapter'));
	END LOOP;
	security.user_pkg.logonadmin;
END;
/




-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/filter_pkg
@../../../aspen2/cms/db/tab_pkg
@../chain/company_product_pkg

@../../../aspen2/cms/db/filter_body
@../../../aspen2/cms/db/tab_body
@../chain/company_product_body
@../chain/product_report_body
@../enable_body
@../plugin_body
@../csrimp/imp_body

@update_tail
