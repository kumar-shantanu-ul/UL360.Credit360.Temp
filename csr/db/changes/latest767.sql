define version=767
@update_header

DECLARE
    v_card_id         chain.card.card_id%TYPE;
    v_desc            chain.card.description%TYPE;
    v_class           chain.card.class_type%TYPE;
    v_js_path         chain.card.js_include%TYPE;
    v_js_class        chain.card.js_class_type%TYPE;
    v_css_path        chain.card.css_include%TYPE;
	type t_string_list is table of varchar2(4000);
    v_actions         chain.t_string_list;
BEGIN

	UPDATE chain.card SET class_type = 'Credit360.Chain.Cards.AddCompany'
	WHERE js_class_type = 'Chain.Cards.SearchComponentSupplier';

    -- Chain.Cards.ComponentSupplierWantToInvite
    v_desc := 'Chain.Cards.ComponentSupplierWantToInvite extension for deciding wether to add component supplier user to existing company';
    v_class := 'Credit360.Chain.Cards.ComponentSupplierWantToInvite';
    v_js_path := '/csr/site/chain/cards/componentSupplierWantToInvite.js';
    v_js_class := 'Chain.Cards.ComponentSupplierWantToInvite';
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
       AND action NOT IN ('default','existing-comp-invite','new-comp-invite','no-invite');
    
    v_actions := chain.T_STRING_LIST('default','existing-comp-invite','new-comp-invite','no-invite');
    
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
    
    -- Chain.Cards.AddComponentSupplierUsers
    v_desc := 'Chain.Cards.AddComponentSupplierUsers extension for deciding wether to add component supplier user to existing company';
    v_class := 'Credit360.Chain.Cards.AddUser';
    v_js_path := '/csr/site/chain/cards/addComponentSupplierUsers.js';
    v_js_class := 'Chain.Cards.AddComponentSupplierUsers';
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
       AND action NOT IN ('createnew','default');
    
    v_actions := chain.t_string_list('createnew','default');
    
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
	
@update_tail