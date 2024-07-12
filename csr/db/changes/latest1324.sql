-- Please update version.sql too -- this keeps clean builds in sync
define version=1324
@update_header

BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies 
		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND object_owner = 'CHAIN'
		   AND object_name = 'COMPANY_GROUP_TYPE'
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => 'CHAIN',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

ALTER  TABLE CHAIN.QUESTIONNAIRE_TYPE ADD (
	ALLOW_AUTO_APPROVE       NUMBER(1, 0)      DEFAULT 0 NOT NULL,
	CHECK (ALLOW_AUTO_APPROVE IN (0, 1))
);

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id, c.reference_id_1, c.reference_id_2, c.reference_id_3,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.deleted = 0
;

CREATE OR REPLACE VIEW CHAIN.v$active_invite AS
	SELECT *
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id = 1
;

ALTER TABLE CHAIN.INTIVE_ON_BEHALF_OF RENAME TO INVITE_ON_BEHALF_OF;
ALTER TABLE CHAIN.INVITE_ON_BEHALF_OF RENAME CONSTRAINT PK_INTIVE_ON_BEHALF_OF TO PK_INVITE_ON_BEHALF_OF;

DECLARE
    v_card_id         chain.card.card_id%TYPE;
    v_desc            chain.card.description%TYPE;
    v_class           chain.card.class_type%TYPE;
    v_js_path         chain.card.js_include%TYPE;
    v_js_class        chain.card.js_class_type%TYPE;
    v_css_path        chain.card.css_include%TYPE;
    v_actions         chain.T_STRING_LIST;
BEGIN
    -- Chain.Cards.InviteCompanyType
    v_desc := 'Displays a list of company types that the user can send an invitation to, including on behalf of';
    v_class := 'Credit360.Chain.Cards.InviteCompanyType';
    v_js_path := '/csr/site/chain/cards/inviteCompanyType.js';
    v_js_class := 'Chain.Cards.InviteCompanyType';
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


@..\chain\capability_pkg
@..\chain\company_pkg
@..\chain\company_type_pkg
@..\chain\company_user_pkg
@..\chain\invitation_pkg
@..\chain\questionnaire_pkg
@..\chain\setup_pkg
@..\chain\type_capability_pkg

@..\chain\capability_body
@..\chain\company_body
@..\chain\company_type_body
@..\chain\company_user_body
@..\chain\invitation_body
@..\chain\questionnaire_body
@..\chain\setup_body
@..\chain\type_capability_body


@update_tail
