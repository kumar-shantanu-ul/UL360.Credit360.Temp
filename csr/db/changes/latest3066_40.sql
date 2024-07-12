-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=40
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csrimp.map_compl_activity_sub_type ADD (
	old_complianc_activity_type_id	NUMBER(10) NOT NULL, 
	new_complianc_activity_type_id	NUMBER(10) NOT NULL
);

ALTER TABLE csrimp.map_compl_activity_sub_type
DROP CONSTRAINT PK_MAP_COMPL_ACTIVIT_SUB_TYPE;

ALTER TABLE csrimp.map_compl_activity_sub_type
DROP CONSTRAINT UK_MAP_COMPL_ACTIVIT_SUB_TYPE;

ALTER TABLE csrimp.map_compl_activity_sub_type ADD
CONSTRAINT PK_MAP_COMPL_ACTIVIT_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_ACTIVITY_TYPE_ID, OLD_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX;

ALTER TABLE csrimp.map_compl_activity_sub_type ADD
CONSTRAINT UK_MAP_COMPL_ACTIVIT_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_ACTIVITY_TYPE_ID, NEW_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX;

ALTER TABLE csrimp.map_compl_permi_sub_type ADD (
	old_compliance_permit_type_id	NUMBER(10) NOT NULL, 
	new_compliance_permit_type_id	NUMBER(10) NOT NULL
);

ALTER TABLE csrimp.map_compl_permi_sub_type
DROP CONSTRAINT PK_MAP_COMPL_PERMI_SUB_TYPE;

ALTER TABLE csrimp.map_compl_permi_sub_type
DROP CONSTRAINT UK_MAP_COMPL_PERMI_SUB_TYPE;

ALTER TABLE csrimp.map_compl_permi_sub_type ADD
CONSTRAINT PK_MAP_COMPL_PERMI_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_TYPE_ID, OLD_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX;

ALTER TABLE csrimp.map_compl_permi_sub_type ADD
CONSTRAINT UK_MAP_COMPL_PERMI_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_TYPE_ID, NEW_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX;
	

ALTER TABLE csrimp.map_complia_condition_sub_type ADD (
	old_complian_condition_type_id	NUMBER(10) NOT NULL, 
	new_complian_condition_type_id	NUMBER(10) NOT NULL
);

ALTER TABLE csrimp.map_complia_condition_sub_type
DROP CONSTRAINT PK_MAP_COMP_CONDITION_SUB_TYPE;

ALTER TABLE csrimp.map_complia_condition_sub_type
DROP CONSTRAINT UK_MAP_COMP_CONDITION_SUB_TYPE;

ALTER TABLE csrimp.map_complia_condition_sub_type ADD
CONSTRAINT PK_MAP_COMP_CONDITION_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIAN_CONDITION_TYPE_ID, OLD_COMP_CONDITION_SUB_TYPE_ID) USING INDEX;

ALTER TABLE csrimp.map_complia_condition_sub_type ADD
CONSTRAINT UK_MAP_COMP_CONDITION_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIAN_CONDITION_TYPE_ID, NEW_COMP_CONDITION_SUB_TYPE_ID) USING INDEX;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO cms.col_type
(col_type, description) 
VALUES
(40, 'Permit');
	
UPDATE chain.card 
   SET description = 'CMS Data Adapter',
		class_type = 'NPSL.Cms.Cards.CmsAdapter',
		js_include = '/fp/cms/filters/CmsAdapter.js',
		js_class_type = 'NPSL.Cms.Filters.CmsFilterAdapter'
 WHERE LOWER(js_class_type) = LOWER('NPSL.Cms.Filters.CmsFilterAdaptor');

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
	v_desc := 'Permit CMS Adapter';
	v_class := 'Credit360.Compliance.Cards.PermitCmsFilterAdapter';
	v_js_path := '/csr/site/compliance/filters/PermitCmsFilterAdapter.js';
	v_js_class := 'Credit360.Compliance.Filters.PermitCmsFilterAdapter';
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
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'Permit CMS Filter',
				'csr.permit_report_pkg',
				v_card_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'Permit CMS Filter',
					   helper_pkg = 'csr.permit_report_pkg'
				 WHERE card_id = v_card_id;
	END;
END;
/

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
	v_desc := 'User CMS Adapter';
	v_class := 'Credit360.Schema.Cards.UserCmsFilterAdapter';
	v_js_path := '/csr/site/users/list/filters/UserCmsFilterAdapter.js';
	v_js_class := 'Credit360.Users.Filters.UserCmsFilterAdapter';
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
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'User CMS Filter',
				'csr.user_report_pkg',
				v_card_id
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'User CMS Filter',
					   helper_pkg = 'csr.user_report_pkg'
				 WHERE card_id = v_card_id;
	END;
END;
/
 
DECLARE
	PROCEDURE SetGroupCards(
		in_group_name			IN  chain.card_group.name%TYPE,
		in_card_js_types		IN  chain.T_STRING_LIST
	)
	AS
		v_group_id				chain.card_group.card_group_id%TYPE;
		v_card_id				chain.card.card_id%TYPE;
		v_pos					NUMBER(10) DEFAULT 0;
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
		
		DELETE FROM chain.card_group_progression
		 WHERE app_sid = security.security_pkg.GetApp
		   AND card_group_id = v_group_id;
		
		DELETE FROM chain.card_group_card
		 WHERE app_sid = security.security_pkg.GetApp
		   AND card_group_id = v_group_id;
		
		-- empty array check
		IF in_card_js_types IS NULL OR in_card_js_types.COUNT = 0 THEN
			RETURN;
		END IF;
		
		FOR i IN in_card_js_types.FIRST .. in_card_js_types.LAST 
		LOOP		
			SELECT card_id
			  INTO v_card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER(in_card_js_types(i));

			INSERT INTO chain.card_group_card
			(card_group_id, card_id, position)
			VALUES
			(v_group_id, v_card_id, v_pos);
			
			v_pos := v_pos + 1;
		
		END LOOP;		
	END;		
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host 
		  FROM csr.customer c
		  JOIN chain.card_group_card cgc on c.app_sid = cgc.app_sid
		 WHERE card_group_id = 47 
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		EXCEPTION
			WHEN OTHERS THEN
				CONTINUE;
		END;
		--chain.card_pkg.SetGroupCards
		SetGroupCards('User Data Filter', chain.T_STRING_LIST('Credit360.Users.Filters.UserDataFilter', 'Credit360.Users.Filters.UserCmsFilterAdapter'));
	END LOOP;
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT host 
		  FROM csr.customer c
		  JOIN csr.compliance_options co on co.app_sid = c.app_sid
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		EXCEPTION
			WHEN OTHERS THEN
				CONTINUE;
		END;
		--chain.card_pkg.SetGroupCards
		SetGroupCards('Compliance Permit Filter', chain.T_STRING_LIST('Credit360.Compliance.Filters.PermitFilter', 'Credit360.Compliance.Filters.PermitCmsFilterAdapter'));
	END LOOP;
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../permit_pkg
@../permit_report_pkg

@../enable_body
@../permit_body
@../permit_report_body
@../csr_app_body
@../schema_body
@../user_report_body

@../csrimp/imp_body

@../../../aspen2/cms/db/tab_pkg

@../../../aspen2/cms/db/tab_body

@update_tail
