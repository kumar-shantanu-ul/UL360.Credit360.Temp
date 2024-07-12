-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
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
	PROCEDURE CreateFilterType (
		in_description			chain.filter_type.description%TYPE,
		in_helper_pkg			chain.filter_type.helper_pkg%TYPE,
		in_js_class_type		chain.card.js_class_type%TYPE,
		in_update				NUMBER DEFAULT 0
	)
	AS
		v_filter_type_id		chain.filter_type.filter_type_id%TYPE;
		v_card_id				chain.card.card_id%TYPE;
	BEGIN
		-- N.B. card data is present on CI build DB
		BEGIN
			SELECT card_id
			  INTO v_card_id
			  FROM chain.card
			 WHERE LOWER(js_class_type) = LOWER(in_js_class_type);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;
		
		BEGIN
			SELECT filter_type_id
			  INTO v_filter_type_id
			  FROM chain.filter_type
			 WHERE card_id = v_card_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
		
		IF v_filter_type_id IS NULL THEN
			INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				in_description,
				in_helper_pkg,
				v_card_id
			);
		ELSIF in_update = 1 THEN
			UPDATE chain.filter_type
			   SET description = in_description
			 WHERE card_id = v_card_id;
		END IF;
	END;
BEGIN
	CreateFilterType (
		in_description => 'Chain Core Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCore'
	);
	
	CreateFilterType (
		in_description => 'Chain Company Tags Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyTagsFilter'
	);
	
	CreateFilterType (
		in_description => 'Survey Questionnaire Filter',
		in_helper_pkg => 'csr.quick_survey_pkg',
		in_js_class_type => 'Chain.Cards.Filters.SurveyQuestionnaire'
	);
	
	CreateFilterType (
		in_description => 'Issue Filter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.StandardIssuesFilter'
	);
	
	-- This is called Credit360.Filters.Issues.IssuesCustomFieldsFilter on live. Update description
	-- to match basedata and keep everything in sync
	CreateFilterType (
		in_description => 'Issue Custom Fields Filter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.IssuesCustomFieldsFilter',
		in_update => 1
	);
	
	-- The following are on live but are in neither basedata nor change scripts. First three are client specific
	-- so don't care (because latest scripts shouldn't be referencing these). Last two look like core, but I can't
	-- find references elsewhere so will just have to leave it.
	
	--	ChainDemo Risk Filter
	--	Otto Company Filter Sandbox
	--	McD Workflow Filter
	--	Compliance Requirement Data Filter
	--	Compliance Regulaton Data Filter
END;
/

-- Lifted from latest3035_6
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
	SELECT filter_type_id
	  INTO v_company_filter_type_id
	  FROM chain.filter_type
	 WHERE description = 'Chain Core Filter';

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

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\filter_body

@update_tail
