-- Please update version.sql too -- this keeps clean builds in sync
define version=3416
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Sheet list', 0);

CREATE INDEX csr.ix_delegation_ro_deleg_sid ON csr.delegation_role (app_sid, delegation_sid);

DECLARE
	v_card_id				NUMBER(10);
	PROCEDURE SetGroupCards(
		in_group_name			IN  chain.card_group.name%TYPE,
		in_card_js_types		IN  chain.T_STRING_LIST
	)
	AS
		v_group_id				chain.card_group.card_group_id%TYPE;
		v_card_id				chain.card.card_id%TYPE;
		v_pos					NUMBER(10) := 1;
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

	INSERT INTO chain.card_group
	(card_group_id, name, description, helper_pkg, list_page_url)
	VALUES
	(69, 'Sheet Filter', 'Allows filtering of sheets', 'csr.sheet_report_pkg', '/csr/site/delegation/sheet2/list/List.acds?savedFilterSid=');
	
	v_card_id := chain.card_id_seq.NEXTVAL;
	
	INSERT INTO chain.card
	(card_id, description, class_type, js_include, js_class_type, css_include)
	VALUES
	(v_card_id, 'Sheet Filter', 'Credit360.Delegation.Cards.SheetDataFilter', '/csr/site/delegation/sheet2/list/filters/DataFilter.js', 'Credit360.Delegation.Sheet.Filters.DataFilter', null);

	INSERT INTO chain.filter_type (
		filter_type_id,
		description,
		helper_pkg,
		card_id
	) VALUES (
		chain.filter_type_id_seq.NEXTVAL,
		'Sheet Filter',
		'csr.sheet_report_pkg',
		v_card_id
	);
    
    INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (69, 1, 'Number of records');
    
	FOR r IN (
		SELECT host 
		  FROM csr.customer c
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		EXCEPTION
			WHEN OTHERS THEN
				CONTINUE;
		END;
		--chain.card_pkg.SetGroupCards
		SetGroupCards('Sheet Filter', chain.T_STRING_LIST('Credit360.Delegation.Sheet.Filters.DataFilter'));
	END LOOP;
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.sheet_report_pkg AS END;
/

GRANT EXECUTE ON csr.sheet_report_pkg TO chain;
GRANT EXECUTE ON csr.sheet_report_pkg TO web_user; 

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../sheet_report_pkg

@../csr_app_body
@../sheet_report_body

@update_tail
