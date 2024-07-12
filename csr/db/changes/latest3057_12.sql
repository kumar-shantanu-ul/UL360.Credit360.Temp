-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=12
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
	security.user_pkg.LogonAdmin;
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
	
	UPDATE chain.card_group
	   SET list_page_url = '/csr/site/chain/certificationList.acds?savedFilterSid='
	 WHERE card_group_id = 55; /* filter_pkg.FILTER_TYPE_CERTS */
	
	v_desc := 'Certification Company Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.CertificationCompanyFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/certificationCompanyFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.CertificationCompanyFilterAdapter';
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
	v_card_id				NUMBER(10);
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CertificationCompanyFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Certification Company Filter Adapter', 'chain.certification_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	

	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		   FROM chain.card_group_card
		  WHERE card_group_id = 55 /*chain.filter_pkg.FILTER_TYPE_CERTS*/
		  GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
				 VALUES (r.app_sid, 55 /*chain.filter_pkg.FILTER_TYPE_CERTS*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (55 /*chain.filter_pkg.FILTER_TYPE_CERTS*/, 1 /*chain.business_rel_report_pkg.AGG_TYPE_COUNT*/, 'Number of certifications');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\certification_report_pkg

@..\enable_body
@..\chain\certification_report_body
@..\chain\chain_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\setup_body

@update_tail
