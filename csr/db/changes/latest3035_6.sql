-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=6
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
	v_desc := 'Business Relationship Filter';
	v_class := 'Credit360.Chain.Cards.Filters.BusinessRelationshipFilter';
	v_js_path := '/csr/site/chain/cards/filters/businessRelationshipFilter.js';
	v_js_class := 'Chain.Cards.Filters.BusinessRelationshipFilter';
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

	v_desc := 'Business Relationship Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.BusinessRelationshipFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/businessRelationshipFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.BusinessRelationshipFilterAdapter';
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

	v_desc := 'Company Business Relationship Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/companyBusinessRelationshipFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter';
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
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, 'Business Relationship Filter', 'Allows filtering of business relationships', 'chain.business_rel_report_pkg', '/csr/site/chain/businessRelationshipList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.BusinessRelationshipFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Business Relationship Filter', 'chain.business_rel_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		BEGIN	
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
				 VALUES (r.app_sid, 53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, v_card_id, 0);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.BusinessRelationshipFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Business Relationship Filter Adapter', 'chain.business_rel_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	

	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
				 VALUES (r.app_sid, 53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, v_card_id, 0);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Chain Company Business Relationship Filter Adapter', 'chain.company_filter_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	

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

BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, 1 /*chain.business_rel_report_pkg.AGG_TYPE_COUNT*/, 'Number of business relationships');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		VALUES (53 /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/, 1 /*chain.business_rel_report_pkg.COL_TYPE_COMPANY_REGION*/, 1 /*chain.filter_pkg.COLUMN_TYPE_REGION*/, 'Company region');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

DECLARE
	v_plugin_id			NUMBER(10);
BEGIN
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE js_class = 'Chain.ManageCompany.BusinessRelationships';

		UPDATE csr.plugin
		   SET description = 'Business Relationship List',
			   js_include = '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js',
			   js_class = 'Chain.ManageCompany.BusinessRelationshipListTab',
			   cs_class = 'Credit360.Chain.CompanyManagement.BusinessRelationshipListTab',
			   details = 'This tab displays a filterable and searchable table of all business relationships of which the supplier being viewed is a member, that the logged in user has permission to see.'
		 WHERE plugin_id = v_plugin_id;
	EXCEPTION
		WHEN no_data_found THEN
			BEGIN
				INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
				VALUES (csr.plugin_id_seq.NEXTVAL, 10, 'Business Relationship List', '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js', 'Chain.ManageCompany.BusinessRelationshipListTab', 'Credit360.Chain.CompanyManagement.BusinessRelationshipListTab', 'This tab displays a filterable and searchable table of all business relationships of which the supplier being viewed is a member, that the logged in user has permission to see.');
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
	END;
END;
/

DECLARE
	v_company_filter_type_id	NUMBER(10);
	v_bus_rel_filter_type_id	NUMBER(10);
	v_company_fil_adp_type_id	NUMBER(10);
	v_bus_rel_fil_adp_type_id	NUMBER(10);

	v_business_rel_type_id		NUMBER(10);
	v_business_rel_type_label	VARCHAR2(255);

	v_company_comp_filt_id		NUMBER(10);
	v_company_filter_id			NUMBER(10);
	v_company_filt_field_id		NUMBER(10);

	v_bus_rel_comp_filt_id		NUMBER(10);
	v_bus_rel_adp_filter_id		NUMBER(10);
	v_bus_rel_adp_filt_field_id	NUMBER(10);
	v_bus_rel_typ_filter_id		NUMBER(10);
	v_bus_rel_typ_filt_field_id	NUMBER(10);
	
	v_filter_field_count		NUMBER;
	v_filter_id					NUMBER(10);
	v_filter_field_id			NUMBER(10);
BEGIN
	BEGIN
		SELECT filter_type_id
		  INTO v_company_filter_type_id
		  FROM chain.filter_type
		 WHERE description = 'Chain Core Filter';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- This is happening on CI build because the filter type is not in any change
			-- script. This script has probably already been run, so skip it for now, but
			-- we'll need another change script to add the missing filter types and then do
			-- this bit
			RETURN;
	END;

	SELECT filter_type_id
	  INTO v_bus_rel_filter_type_id
	  FROM chain.filter_type
	 WHERE description = 'Business Relationship Filter';
	 
	SELECT filter_type_id
	  INTO v_company_fil_adp_type_id
	  FROM chain.filter_type
	 WHERE description = 'Chain Company Business Relationship Filter Adapter';
	 
	SELECT filter_type_id
	  INTO v_bus_rel_fil_adp_type_id
	  FROM chain.filter_type
	 WHERE description = 'Business Relationship Filter Adapter';

	FOR site IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c 
		 WHERE EXISTS (
				SELECT null
				  FROM chain.filter_field ff
				 WHERE ff.app_sid = c.app_sid
				   AND ff.name LIKE 'BusinessRelationship.%'
		)
	) LOOP
		security.user_pkg.logonadmin(site.host);

		FOR r IN (
			SELECT cf.compound_filter_id, cf.created_by_user_sid, cf.card_group_id, cf.act_id,
				   f.filter_id, ff.filter_field_id, ff.name
			  FROM chain.filter_field ff
			  JOIN chain.filter f ON f.filter_id = ff.filter_id
			  JOIN chain.compound_filter cf ON cf.compound_filter_id = f.compound_filter_id
			 WHERE ff.app_sid = site.app_sid
			   AND ff.name LIKE 'BusinessRelationship.%'
			   AND cf.card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		) LOOP

			v_business_rel_type_id := TO_NUMBER(SUBSTR(r.name, 22));

			SELECT label 
			  INTO v_business_rel_type_label
			  FROM chain.business_relationship_type
			 WHERE business_relationship_type_id = v_business_rel_type_id;

			-- Create a compound filter that filters companies to the ones in the existing CF.

			INSERT INTO chain.compound_filter (
				compound_filter_id,
				operator_type,
				created_dtm,
				created_by_user_sid,
				card_group_id,
				act_id,
				read_only_saved_filter_sid,
				is_read_only_group_by
			) VALUES (
				chain.compound_filter_id_seq.nextval,
				'and',
				SYSDATE,
				r.created_by_user_sid,
				23, /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
				r.act_id,
				NULL,
				0
			)
			RETURNING compound_filter_id INTO v_company_comp_filt_id;

			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_company_filter_type_id, /* Company core */
				v_company_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_company_filter_id;

			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_company_filter_id,
				'CompanySid',
				'equals'
			) RETURNING filter_field_id INTO v_company_filt_field_id;
			
			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				num_value,
				description,
				pos
			) SELECT
				chain.filter_value_id_seq.nextval,
				v_company_filt_field_id,
				num_value,
				description,
				pos
			FROM chain.filter_value WHERE filter_field_id = r.filter_field_id;

			-- Create a business relationship filter containing the above one, and also a type filter
			
			INSERT INTO chain.compound_filter (
				compound_filter_id,
				operator_type,
				created_dtm,
				created_by_user_sid,
				card_group_id,
				act_id,
				read_only_saved_filter_sid,
				is_read_only_group_by
			) VALUES (
				chain.compound_filter_id_seq.nextval,
				'and',
				SYSDATE,
				r.created_by_user_sid,
				53, /*chain.filter_pkg.FILTER_TYPE_BUS_RELS*/
				r.act_id,
				NULL,
				0
			)
			RETURNING compound_filter_id INTO v_bus_rel_comp_filt_id;

			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_bus_rel_fil_adp_type_id, /* Business relationship adapter */
				v_bus_rel_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_bus_rel_adp_filter_id;
			
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_bus_rel_adp_filter_id,
				'CompanyFilter',
				'equals'
			) RETURNING filter_field_id INTO v_bus_rel_adp_filt_field_id;

			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				compound_filter_id_value
			) VALUES (
				chain.filter_value_id_seq.nextval,
				v_bus_rel_adp_filt_field_id,
				v_company_comp_filt_id
			);

			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_bus_rel_filter_type_id, /* Business relationship */
				v_bus_rel_comp_filt_id,
				'and'
			) RETURNING filter_id INTO v_bus_rel_typ_filter_id;
			
			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_bus_rel_typ_filter_id,
				'BusinessRelationshipTypeId',
				'equals'
			) RETURNING filter_field_id INTO v_bus_rel_typ_filt_field_id;

			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				num_value
			) VALUES ( 
				chain.filter_value_id_seq.nextval,
				v_bus_rel_typ_filt_field_id,
				v_business_rel_type_id
			);
			
			-- Finally replace the existing filter field with one that filters companies using the business relationship CF.
			
			DELETE FROM chain.filter_value
			 WHERE filter_field_id = r.filter_field_id;

			DELETE FROM chain.filter_field
			 WHERE filter_field_id = r.filter_field_id;

			SELECT COUNT(*) 
			  INTO v_filter_field_count
			  FROM chain.filter_field
			 WHERE filter_id = r.filter_id;

			IF v_filter_field_count = 0 THEN
				DELETE FROM chain.filter
				 WHERE filter_id = r.filter_id;
			END IF;

			INSERT INTO chain.filter (
				filter_id,
				filter_type_id,
				compound_filter_id,
				operator_type
			) VALUES (
				chain.filter_id_seq.nextval,
				v_company_fil_adp_type_id, /* Company Business Relationship Adapter */
				r.compound_filter_id,
				'and'
			) RETURNING filter_id INTO v_filter_id;

			INSERT INTO chain.filter_field (
				filter_field_id,
				filter_id,
				name,
				comparator
			) VALUES (
				chain.filter_field_id_seq.nextval,
				v_filter_id,
				'BusinessRelationshipFilter',
				'equals'
			) RETURNING filter_field_id INTO v_filter_field_id;

			INSERT INTO chain.filter_value (
				filter_value_id,
				filter_field_id,
				compound_filter_id_value
			) VALUES ( 
				chain.filter_value_id_seq.nextval,
				v_filter_field_id,
				v_bus_rel_comp_filt_id
			);
			
		END LOOP;
	END LOOP;

	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **
create or replace package chain.business_rel_report_pkg as end;
/

grant execute on chain.business_rel_report_pkg to csr;
grant execute on chain.business_rel_report_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/business_relationship_pkg
@../chain/business_rel_report_pkg
@../chain/company_filter_pkg
@../chain/filter_pkg
@../chain/type_capability_pkg

@../chain/chain_body
@../chain/business_relationship_body
@../chain/business_rel_report_body
@../chain/company_filter_body
@../chain/filter_body
@../chain/setup_body
@../chain/type_capability_body

@update_tail
