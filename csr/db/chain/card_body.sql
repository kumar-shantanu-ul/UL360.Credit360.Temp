CREATE OR REPLACE PACKAGE BODY CHAIN.card_pkg
IS

DEFAULT_ACTION 				CONSTANT VARCHAR2(10) := 'default';

PROCEDURE GetActiveCards (
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.card_id, c.description, c.class_type, c.js_class_type, c.js_include, c.css_include 
		  FROM chain.card_group_card cgc
		  JOIN chain.card c ON c.card_id = cgc.CARD_ID
		 GROUP BY c.card_id, c.description, c.class_type, c.js_class_type, c.js_include, c.css_include; 
END;

PROCEDURE DumpCard (
	in_js_class				IN  card.js_class_type%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DumpCard can only be run as BuiltIn/Administrator');
	END IF;

	DumpCards(T_STRING_LIST(in_js_class));
END;

PROCEDURE DumpCards (
	in_js_classes			IN  T_STRING_LIST
)
AS
	v_actions				VARCHAR2(4000);
	v_sep					VARCHAR2(2);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DumpCards can only be run as BuiltIn/Administrator');
	END IF;
	
	dbms_output.put_line('DECLARE');
	dbms_output.put_line('    v_card_id         chain.card.card_id%TYPE;');
	dbms_output.put_line('    v_desc            chain.card.description%TYPE;');
	dbms_output.put_line('    v_class           chain.card.class_type%TYPE;');
	dbms_output.put_line('    v_js_path         chain.card.js_include%TYPE;');
	dbms_output.put_line('    v_js_class        chain.card.js_class_type%TYPE;');
	dbms_output.put_line('    v_css_path        chain.card.css_include%TYPE;');
	dbms_output.put_line('    v_actions         chain.T_STRING_LIST;');
	dbms_output.put_line('BEGIN');

	
	FOR i IN in_js_classes.FIRST .. in_js_classes.LAST
	LOOP
		FOR c IN (
			SELECT *
			  FROM card
			 WHERE js_class_type = in_js_classes(i)
		) LOOP
			v_actions := '';
			v_sep := '';

			FOR a IN (
				SELECT * 
				  FROM card_progression_action
				 WHERE card_id = c.card_id
			) LOOP
					v_actions := v_actions || v_sep || '''' || a.ACTION || '''';
					v_sep := ',';
			END LOOP;
			
			dbms_output.put_line('    -- '||c.js_class_type);
			dbms_output.put_line('    v_desc := '''||REPLACE(c.description, '''', '''''')||''';');
			dbms_output.put_line('    v_class := '''||c.class_type||''';');
			dbms_output.put_line('    v_js_path := '''||c.js_include||''';');
			dbms_output.put_line('    v_js_class := '''||c.js_class_type||''';');
			dbms_output.put_line('    v_css_path := '''||c.css_include||''';');
			dbms_output.put_line('    ');
			dbms_output.put_line('    BEGIN');
			dbms_output.put_line('        INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)');
			dbms_output.put_line('        VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)');
			dbms_output.put_line('        RETURNING card_id INTO v_card_id;');
			dbms_output.put_line('    EXCEPTION ');
			dbms_output.put_line('        WHEN DUP_VAL_ON_INDEX THEN');
			dbms_output.put_line('            UPDATE chain.card ');
			dbms_output.put_line('               SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path');
			dbms_output.put_line('             WHERE js_class_type = v_js_class');
			dbms_output.put_line('         RETURNING card_id INTO v_card_id;');
			dbms_output.put_line('    END;');
			dbms_output.put_line('    ');
			dbms_output.put_line('    DELETE FROM chain.card_progression_action ');
			dbms_output.put_line('     WHERE card_id = v_card_id ');
			dbms_output.put_line('       AND action NOT IN ('||v_actions||');');
			dbms_output.put_line('    ');
			dbms_output.put_line('    v_actions := chain.T_STRING_LIST('||v_actions||');');			
			dbms_output.put_line('    ');
			dbms_output.put_line('    FOR i IN v_actions.FIRST .. v_actions.LAST');
			dbms_output.put_line('    LOOP');
			dbms_output.put_line('        BEGIN');
			dbms_output.put_line('            INSERT INTO chain.card_progression_action (card_id, action)');
			dbms_output.put_line('            VALUES (v_card_id, v_actions(i));');
			dbms_output.put_line('        EXCEPTION ');
			dbms_output.put_line('            WHEN DUP_VAL_ON_INDEX THEN');
			dbms_output.put_line('                NULL;');
			dbms_output.put_line('        END;');
			dbms_output.put_line('    END LOOP;');
			dbms_output.put_line('    ');
		END LOOP;
	END LOOP;
	
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
END;

PROCEDURE DumpGroup (
	in_group_name			IN  card_group.name%TYPE,
	in_host					IN  v$chain_host.host%TYPE
)
AS
	v_card_group_id			card_group.card_group_id%TYPE;
	v_card_group_name		card_group.name%TYPE;
	v_card_group_desc		card_group.description%TYPE;
	v_helper_pkg			card_group.helper_pkg%TYPE;
	v_app_sid				security_pkg.T_SID_ID;
	v_chain_implementation  v$chain_host.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DumpGroup can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		SELECT card_group_id, name, description, helper_pkg
		  INTO v_card_group_id, v_card_group_name, v_card_group_desc, v_helper_pkg
		  FROM card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = '''||in_group_name||'''');
	END;
	
	SELECT app_sid, name
	  INTO v_app_sid, v_chain_implementation
	  FROM v$chain_host
	 WHERE LOWER(host) = LOWER(in_host);
	
	dbms_output.put_line('-- '||in_group_name||' (copied from '||in_host||')');
	dbms_output.put_line('BEGIN');
	dbms_output.put_line('    INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg)');
	dbms_output.put_line('    VALUES('||v_card_group_id||', '''||v_card_group_name||''', '''||replace(v_card_group_desc, '''', '''''')||''', '''||v_helper_pkg||''');');
	dbms_output.put_line('EXCEPTION');
	dbms_output.put_line('    WHEN DUP_VAL_ON_INDEX THEN');
	dbms_output.put_line('        UPDATE chain.card_group');
	dbms_output.put_line('           SET description='''||replace(v_card_group_desc, '''', '''''')||''',');
	dbms_output.put_line('               helper_pkg='''||v_helper_pkg||'''');
	dbms_output.put_line('         WHERE card_group_id='||v_card_group_id||';');
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
	dbms_output.put_line('');
	dbms_output.put_line('DECLARE');
	dbms_output.put_line('    v_card_group_id			chain.card_group.card_group_id%TYPE DEFAULT '||v_card_group_id||';');
	dbms_output.put_line('    v_position				NUMBER(10) DEFAULT 1;');
	dbms_output.put_line('BEGIN');
	dbms_output.put_line('    ');
	dbms_output.put_line('    -- clear the app_sid');
	dbms_output.put_line('    security.user_pkg.logonadmin;');
	dbms_output.put_line('    ');
	dbms_output.put_line('    FOR r IN (');
	dbms_output.put_line('        SELECT host FROM chain.v$chain_host WHERE name = '''||v_chain_implementation||'''');
	dbms_output.put_line('    ) LOOP');
	dbms_output.put_line('        ');
	dbms_output.put_line('        security.user_pkg.logonadmin(r.host);');
	dbms_output.put_line('        ');
	dbms_output.put_line('        DELETE FROM chain.card_group_progression');
	dbms_output.put_line('         WHERE app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')');
	dbms_output.put_line('           AND card_group_id = v_card_group_id;');
	dbms_output.put_line('        ');
	dbms_output.put_line('        DELETE FROM chain.card_group_card');
	dbms_output.put_line('         WHERE app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')');
	dbms_output.put_line('           AND card_group_id = v_card_group_id;');
	dbms_output.put_line('        ');
	FOR r IN (
		SELECT c.js_class_type, cgc.position, c.card_id, cgc.required_permission_set, cgc.invert_capability_check, cgc.force_terminate,
				cap.capability_name, cap.capability_type_id
		  FROM card_group_card cgc
		  JOIN card c ON cgc.card_id = c.card_id
		  LEFT JOIN capability cap ON cgc.required_capability_id=cap.capability_id
		 WHERE cgc.app_sid = v_app_sid
		   AND cgc.card_group_id = v_card_group_id
		 ORDER BY cgc.position
	) LOOP
		dbms_output.put_line('        INSERT INTO chain.card_group_card (card_group_id, card_id, position, required_permission_set,');
		dbms_output.put_line('               invert_capability_check, force_terminate, required_capability_id)');
		IF r.capability_name IS NULL THEN
			dbms_output.put_line('            SELECT v_card_group_id, card_id, v_position, '||NVL(CAST(r.required_permission_set as nvarchar2),'NULL')||', '||
								r.invert_capability_check||', '||r.force_terminate||', NULL');
			dbms_output.put_line('              FROM chain.card');
			dbms_output.put_line('             WHERE js_class_type = '''||r.js_class_type||''';');
		ELSE
			dbms_output.put_line('            SELECT v_card_group_id, card_id, v_position, '||NVL(CAST(r.required_permission_set as nvarchar2),'NULL')||', '||
								r.invert_capability_check||', '||r.force_terminate||', capability_id');
			dbms_output.put_line('              FROM chain.card, chain.capability');
			dbms_output.put_line('             WHERE js_class_type = '''||r.js_class_type||'''');
			dbms_output.put_line('               AND capability_name = '''||r.capability_name||'''');
			dbms_output.put_line('               AND capability_type_id = '||r.capability_type_id||';');
		END IF;
		dbms_output.put_line('        ');
		dbms_output.put_line('        v_position := v_position + 1;');
		dbms_output.put_line('        ');
	END LOOP;
	
	FOR pa IN (
		SELECT f.js_class_type from_js_class_type, t.js_class_type to_js_class_type, p.from_card_action
		  FROM card_group_progression p
		  JOIN card f ON p.from_card_id = f.card_id
		  JOIN card t ON p.to_card_id = t.card_id
		 WHERE p.card_group_id = v_card_group_id
		   AND p.app_sid = v_app_sid
	) LOOP
		dbms_output.put_line('        INSERT INTO chain.card_group_progression');
		dbms_output.put_line('        (card_group_id, from_card_id, from_card_action, to_card_id)');
		dbms_output.put_line('        SELECT v_card_group_id, f.card_id, '''||pa.from_card_action||''', t.card_id');
		dbms_output.put_line('          FROM chain.card f, chain.card t');
		dbms_output.put_line('         WHERE f.js_class_type = '''||pa.from_js_class_type||'''');
		dbms_output.put_line('           AND t.js_class_type = '''||pa.to_js_class_type||''';');
		dbms_output.put_line('        ');
	END LOOP;

	
	dbms_output.put_line('    END LOOP;');
	dbms_output.put_line('    ');
	dbms_output.put_line('    -- clear the app_sid');
	dbms_output.put_line('    security.user_pkg.logonadmin;');
	dbms_output.put_line('    ');
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
END;

PROCEDURE DumpCardsAndGroup (
	in_group_name			IN  card_group.name%TYPE,
	in_host					IN  v$chain_host.host%TYPE
)
AS
	v_js_classes			T_STRING_LIST;
	v_card_group_id			card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
BEGIN
	SELECT c.js_class_type
	  BULK COLLECT INTO v_js_classes
	  FROM card_group_card cgc, card c
	 WHERE cgc.card_id = c.card_id
	 ORDER BY cgc.position;
	
	DumpCards(v_js_classes);
	DumpGroup(in_group_name, in_host);
END;

/*******************************************************************
	Private
*******************************************************************/
-- in reality we can only determine if the inferred type is COMMON or not, 
-- but this gives us a central point to handle the error
FUNCTION GetInferredCapabilityType (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN chain_pkg.T_CAPABILITY_TYPE
AS
BEGIN
	IF capability_pkg.IsCommonCapability(in_capability) THEN
		RETURN chain_pkg.CT_COMMON;
	ELSIF type_capability_pkg.IsOnBehalfOfCapability(in_capability) THEN
		RETURN chain_pkg.CT_ON_BEHALF_OF;
	ELSE 
		RAISE_APPLICATION_ERROR(-20001, 'Cannot infer the capability type from capability '''||in_capability||'''');
	END IF;
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_invert_check			IN  BOOLEAN
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
	v_capability_id			capability.capability_id%TYPE DEFAULT capability_pkg.GetCapabilityId(in_capability_type, in_capability);
	v_icc_val				card_group_card.invert_capability_check%TYPE DEFAULT chain_pkg.INACTIVE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'MakeCardConditional can only be run as BuiltIn/Administrator');
	END IF;
	
	capability_pkg.CheckPermType(v_capability_id, in_expected_pt);
	
	IF in_invert_check THEN 
		v_icc_val := chain_pkg.ACTIVE;
	END IF;
	
	UPDATE card_group_card
	   SET required_capability_id = v_capability_id,
	       required_permission_set = in_permission_set,
	       invert_capability_check = v_icc_val
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
END;

FUNCTION HasProgressionSteps (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE
) RETURN BOOLEAN
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_from_card_id			card.card_id%TYPE DEFAULT GetCardId(in_from_js_class);
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM card_group_progression
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND from_card_id = v_from_card_id;
	 
	RETURN v_count > 0;
END;

FUNCTION IsTerminatingCard (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
) RETURN BOOLEAN
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
	v_force_terminate		card_group_card.force_terminate%TYPE;
BEGIN
	SELECT force_terminate
	  INTO v_force_terminate
	  FROM card_group_card
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
	
	RETURN v_force_terminate = chain_pkg.ACTIVE;
END;

/*******************************************************************
	Public
*******************************************************************/
FUNCTION GetCardId (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN card.card_id%TYPE
AS
	v_card_id				card.card_id%TYPE;
	e_too_many_rows			EXCEPTION;
	PRAGMA EXCEPTION_INIT (e_too_many_rows, -01422);	
BEGIN
	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM card
		 WHERE LOWER(js_class_type) = LOWER(in_js_class);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card with js class type = '''||in_js_class||'''');
		WHEN e_too_many_rows THEN
			RAISE_APPLICATION_ERROR(-20001, 'More than one card with js class type = '''||in_js_class||'''');
	END;
    
    RETURN v_card_id;
END;

FUNCTION GetCardGroupId (
	in_group_name			IN  card_group.name%TYPE
) RETURN card_group.card_group_id%TYPE
AS
	v_group_id				card_group.card_group_id%TYPE;
BEGIN
	-- No security check, base data.

	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = '''||in_group_name||'''');
	END;
	
	RETURN v_group_id;
END;

PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card_group.description%TYPE,
	in_helper_pkg			IN  card_group.helper_pkg%TYPE DEFAULT NULL,
	in_list_page_url		IN  card_group.list_page_url%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCardGroup can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO card_group
		(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES
		(in_id, in_name, in_description, in_helper_pkg, in_list_page_url);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE card_group
			   SET name = in_name, 
				   description = in_description,
				   helper_pkg = in_helper_pkg,
				   list_page_url = in_list_page_url
			 WHERE card_group_id = in_id;
	END;	
			
END;

PROCEDURE DestroyCard (
	in_js_class				IN  card.js_class_type%TYPE
)
AS
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DestroyCard can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM card_group_progression
	 WHERE from_card_id = v_card_id
	    OR to_card_id = v_card_id;
	
	DELETE FROM card_progression_action
	 WHERE card_id = v_card_id;

	DELETE FROM card_group_card
	 WHERE card_id = v_card_id;
	
	DELETE FROM card
	 WHERE card_id = v_card_id;	
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
)
AS
BEGIN
	RegisterCard (in_desc, in_class, in_js_path, in_js_class, null, null);
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
)
AS
BEGIN
	RegisterCard (in_desc, in_class, in_js_path, in_js_class, null, in_progression_actions);
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE
)
AS
BEGIN
	RegisterCard (in_desc, in_class, in_js_path, in_js_class, in_css_path, null);
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE,
	in_progression_actions	IN  T_STRING_LIST
)
AS
	v_card_id				card.card_id%TYPE;
	v_found					BOOLEAN;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCard can only be run as BuiltIn/Administrator');
	END IF;
		
	BEGIN
		INSERT INTO card
		(card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES
		(card_id_seq.NEXTVAL, in_desc, in_class, in_js_path, in_js_class, in_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE card 
			   SET description = in_desc,
					class_type = in_class,
					js_include = in_js_path,
					css_include = in_css_path,
					js_class_type = in_js_class
		     WHERE LOWER(js_class_type) = LOWER(in_js_class)
		 RETURNING card_id INTO v_card_id;
	END;
	
	AddProgressionAction(in_js_class, DEFAULT_ACTION);
	
	-- empty array check
	IF in_progression_actions IS NULL OR in_progression_actions.COUNT = 0 THEN
		DELETE FROM card_group_progression
		 WHERE from_card_id = v_card_id
		   AND from_card_action <> DEFAULT_ACTION;
		  
		DELETE FROM card_progression_action
		 WHERE card_id = v_card_id
		   AND action <> DEFAULT_ACTION;
	ELSE
		-- urg - allow non-destructive re-registrations
		-- Note: we're not worried that this isn't a very efficient way of looking at this
		-- as it only happens during card registration
		
		-- loop through existing actions for this card
		FOR r IN (
			SELECT action
			  FROM card_progression_action
			 WHERE card_id = v_card_id
			   AND action <> DEFAULT_ACTION
		) LOOP
			v_found := FALSE;
			
			-- see if we're re-registering the action
			FOR i IN in_progression_actions.FIRST .. in_progression_actions.LAST 
			LOOP
				IF LOWER(TRIM(in_progression_actions(i))) = r.action THEN
					v_found := TRUE;
				END IF;
			END LOOP;
			
			-- if we're not re-registering the action, clean it up
			IF NOT v_found THEN
				DELETE FROM card_group_progression
				 WHERE from_card_id = v_card_id
				   AND from_card_action = r.action;
			
				DELETE FROM card_progression_action
				 WHERE card_id = v_card_id
				   AND action = r.action;
			END IF;		
		END LOOP;
	
		AddProgressionActions(in_js_class, in_progression_actions);
	END IF;	
END;

PROCEDURE AddProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_action	IN  card_progression_action.action%TYPE
)
AS
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
BEGIN	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddProgressionAction can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO card_progression_action
		(card_id, action)
		VALUES
		(v_card_id, LOWER(TRIM(in_progression_action)));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddProgressionActions can only be run as BuiltIn/Administrator');
	END IF;
	
	FOR i IN in_progression_actions.FIRST .. in_progression_actions.LAST 
	LOOP
		AddProgressionAction(in_js_class, in_progression_actions(i));	
	END LOOP;
END;

PROCEDURE RenameProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_from_action 			IN  card_progression_action.action%TYPE,
	in_to_action 			IN  card_progression_action.action%TYPE
)
AS
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
	v_count					NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RenameProgressionAction can only be run as BuiltIn/Administrator');
	END IF;
	
	-- check that the from_action exists
	SELECT COUNT(*)
	  INTO v_card_id
	  FROM card_progression_action
	 WHERE card_id = v_card_id
	   AND action = LOWER(TRIM(in_from_action));
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'A progression action named '''||in_from_action||''' is not registered for card '''||in_js_class||'''');
	END IF;
	
	-- check that the to_action does not exist
	SELECT COUNT(*)
	  INTO v_card_id
	  FROM card_progression_action
	 WHERE card_id = v_card_id
	   AND action = LOWER(TRIM(in_to_action));

	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'A progression action named '''||in_to_action||''' is already registered for card '''||in_js_class||'''');
	END IF;
	
	AddProgressionAction(in_js_class, in_to_action);
	
	UPDATE card_group_progression
	   SET from_card_action = LOWER(TRIM(in_to_action))
	 WHERE from_card_id = v_card_id
	   AND from_card_action = LOWER(TRIM(in_from_action));

	-- if we're currently logged into an application, this may fail because rls prevents us from updating all rows
	-- it's possible that it will succeed if we're logged in, but the progression is not registered in other applications
	DELETE FROM card_progression_action
	  WHERE card_id = v_card_id
	    AND action = LOWER(TRIM(in_from_action));	
END;

FUNCTION GetProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN T_STRING_LIST
AS
	v_list 					T_STRING_LIST;
	v_card_id				card.card_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetProgressionActions can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		v_card_id := GetCardId(in_js_class);
	EXCEPTION
		-- card not found
		WHEN OTHERS THEN
			RETURN NULL;
	END;
	
	SELECT action
	  BULK COLLECT INTO v_list
	  FROM card_progression_action
	 WHERE card_id = v_card_id;
	
	RETURN v_list;
END;

PROCEDURE InsertGroupCard (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_type			IN  card.js_class_type%TYPE,
	in_pos					IN	NUMBER DEFAULT 0
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE;
	v_pos					NUMBER := in_pos;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'InsertGroupCard can only be run as BuiltIn/Administrator');
	END IF;
	
	IF v_pos = -1 THEN
		SELECT MAX(position) + 1
		  INTO v_pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id;
	END IF;
	
	UPDATE card_group_card 
	   SET position = position + 1 
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND position >= v_pos;
	
	v_card_id := GetCardId(in_card_js_type);

	INSERT INTO card_group_card
	(card_group_id, card_id, position)
	VALUES
	(v_group_id, v_card_id, v_pos);
	
END;

PROCEDURE RemoveGroupCard (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_type			IN  card.js_class_type%TYPE
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE;
	v_progressions			NUMBER(10);
	v_pos					NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'InsertGroupCard can only be run as BuiltIn/Administrator');
	END IF;
	
	v_card_id := GetCardId(in_card_js_type);
	
	BEGIN
		SELECT position
		  INTO v_pos
		  FROM card_group_card
		 WHERE app_sid = security_pkg.GetApp
		   AND card_group_id = v_group_id
		   AND card_id = v_card_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Card group '''||in_group_name||''' does not contain a card with name '''||in_card_js_type||'''');
	END;

	SELECT count(*)
	  INTO v_progressions
	  FROM card_group_progression
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND (from_card_id = v_card_id OR to_card_id = v_card_id);

	IF v_progressions > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot add remove a card that is part of a progression');
	END IF;
	
	DELETE FROM card_group_card
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;

	UPDATE card_group_card 
	   SET position = position - 1 
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND position > v_pos;
	
END;

PROCEDURE SetGroupCards (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_types		IN  T_STRING_LIST
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE;
	v_pos					NUMBER(10) DEFAULT 0;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetGroupCards can only be run as BuiltIn/Administrator');
	END IF;
		
	DELETE FROM card_group_progression
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id;
	
	DELETE FROM card_group_card
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id;
	
	-- empty array check
	IF in_card_js_types IS NULL OR in_card_js_types.COUNT = 0 THEN
		RETURN;
	END IF;
	
	FOR i IN in_card_js_types.FIRST .. in_card_js_types.LAST 
	LOOP
	
		v_card_id := GetCardId(in_card_js_types(i));

		INSERT INTO card_group_card
		(card_group_id, card_id, position)
		VALUES
		(v_group_id, v_card_id, v_pos);
		
		v_pos := v_pos + 1;
	
	END LOOP;
	
END;

PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_to_js_class			IN  card.js_class_type%TYPE
)
AS
BEGIN
	RegisterProgression(in_group_name, in_from_js_class, T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW(DEFAULT_ACTION, in_to_js_class)
	));	
END;


PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_action_list			IN  T_CARD_ACTION_LIST
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_from_card_id			card.card_id%TYPE DEFAULT GetCardId(in_from_js_class);
	v_to_card_id			card.card_id%TYPE;
	v_action				T_CARD_ACTION_ROW;
	v_count					NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterProgression can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM card_group_progression
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND from_card_id = v_from_card_id;
	
	IF in_action_list IS NULL OR in_action_list.COUNT = 0 THEN
		RETURN;
	END IF;
	
	IF IsTerminatingCard(in_group_name, in_from_js_class) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot add progression steps to terminating card ('||in_from_js_class||') in card group "'||in_group_name||'"');
	END IF;
	
	FOR i IN in_action_list.FIRST .. in_action_list.LAST 
	LOOP
		v_action := in_action_list(i);
		v_to_card_id := GetCardId(v_action.go_to_js_class);
		
		-- let's give a nicer message than "integrity constraint violated..."
		SELECT COUNT(*)
		  INTO v_count
		  FROM card_progression_action
		 WHERE card_id = v_from_card_id
		   AND action = v_action.on_action;
		
		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Progression action "'||v_action.on_action||'" not found for card "'||in_from_js_class||'"');
		END IF;
		
		-- let's give a nicer message than "integrity constraint violated..."
		SELECT COUNT(*)
		  INTO v_count
		  FROM card_group_card
		 WHERE card_group_id = v_group_id
		   AND card_id = v_from_card_id;
		
		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'From card "'||in_from_js_class||'" not found in card group "'||in_group_name||'"');
		END IF;
		
		-- let's give a nicer message than "integrity constraint violated..."
		SELECT COUNT(*)
		  INTO v_count
		  FROM card_group_card
		 WHERE card_group_id = v_group_id
		   AND card_id = v_to_card_id;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'To card "'||v_action.go_to_js_class||'" not found in card group "'||in_group_name||'"');
		END IF;
		
		INSERT INTO card_group_progression
		(card_group_id, from_card_id, from_card_action, to_card_id)
		VALUES
		(v_group_id, v_from_card_id, v_action.on_action, v_to_card_id);
	END LOOP;
END;

PROCEDURE MarkTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);	
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'MarkTerminate can only be run as BuiltIn/Administrator');
	END IF;
	
	IF HasProgressionSteps(in_group_name, in_js_class) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot mark a card as terminating when it already has progression steps - ('||in_js_class||') in card group '||in_group_name);
	END IF;
	
	UPDATE card_group_card
	   SET force_terminate = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
	
END;

PROCEDURE ClearTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);	
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearTerminate can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE card_group_card
	   SET force_terminate = chain_pkg.INACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
END;


PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, in_invert_check);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, in_invert_check);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, in_invert_check);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, in_invert_check);
END;


PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_card_init_param_cur OUT security_pkg.T_OUTPUT_CUR	
)
AS
	v_cards_to_use			security.T_SID_TABLE := security.T_SID_TABLE(); -- we'll use a sid table to collect card ids
	v_use_card				BOOLEAN;
BEGIN
	-- no sec checks - cards should provide their own sec checks where required
	-- (we need this to work for EVERYONE)
	
	-- we're going to build up a list of cards to include in the manager based on required capability (if set)
	FOR r IN (
		SELECT *
		  FROM card_group_card
		 WHERE app_sid = security_pkg.GetApp
		   AND card_group_id = in_card_group_id
	) LOOP
		-- if there's no required capability, include it
		IF r.required_capability_id IS NULL THEN
			v_use_card := TRUE;
		ELSE
		-- include the card if the capability passes
			IF helper_pkg.UseTypeCapabilities THEN
				v_use_card := type_capability_pkg.CheckCapabilityById(r.required_capability_id, r.required_permission_set, in_supplier_company_sid);
			ELSE
				v_use_card := capability_pkg.CheckCapabilityById(r.required_capability_id, r.required_permission_set);
			END IF;
		END IF;
		
		IF r.invert_capability_check = chain_pkg.ACTIVE THEN
			v_use_card := NOT v_use_card;
		END IF;
		
		-- if we're including the card, add it to tmp table
		IF v_use_card THEN
			v_cards_to_use.EXTEND;
			v_cards_to_use(v_cards_to_use.COUNT) := r.card_id;
		END IF;
	END LOOP;
	
	CollectManagerData(in_card_group_id, v_cards_to_use, out_manager_cur, out_card_cur, out_progression_cur, out_card_init_param_cur);
END;

PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_card_init_param_cur OUT security_pkg.T_OUTPUT_CUR	
)
AS
	v_supplier_company_sid	security_pkg.T_SID_ID DEFAULT NULL;
BEGIN
	GetManagerData(in_card_group_id, v_supplier_company_sid, out_manager_cur, out_card_cur, out_progression_cur, out_card_init_param_cur);
END;

PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_supplier_company_sid	security_pkg.T_SID_ID DEFAULT NULL;
	v_card_init_param_cur	security_pkg.T_OUTPUT_CUR;
BEGIN
	GetManagerData(in_card_group_id, v_supplier_company_sid, out_manager_cur, out_card_cur, out_progression_cur, v_card_init_param_cur);
END;

PROCEDURE CollectManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	in_cards_to_use			IN  security.T_SID_TABLE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_card_init_param_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- get the manager data
	OPEN out_manager_cur FOR
		SELECT card_group_id, name, description, helper_pkg
		  FROM card_group
		 WHERE card_group_id = in_card_group_id;
	
	-- get the card data
	OPEN out_card_cur FOR
		SELECT c.card_id, c.description, c.class_type, c.js_class_type, c.js_include, c.css_include,
			   cg.force_terminate, cg.required_capability_id
		  FROM card c, card_group_card cg
		 WHERE cg.app_sid = security_pkg.GetApp
		   AND cg.card_group_id = in_card_group_id
		   AND cg.card_id = c.card_id
		   AND cg.card_id IN (SELECT COLUMN_VALUE FROM TABLE(in_cards_to_use))
		 ORDER BY position;

	-- get the progression data
	OPEN out_progression_cur FOR
		SELECT fc.js_class_type from_js_class_type, cgp.from_card_action, tc.js_class_type to_js_class_type
		  FROM card_group_progression cgp, card fc, card tc
		 WHERE cgp.app_sid = security_pkg.GetApp
		   AND cgp.card_group_id = in_card_group_id
		   AND cgp.from_card_id IN (SELECT DISTINCT COLUMN_VALUE FROM TABLE(in_cards_to_use))
		   AND cgp.to_card_id IN (SELECT DISTINCT COLUMN_VALUE FROM TABLE(in_cards_to_use))
		   AND cgp.from_card_id = fc.card_id
		   AND cgp.to_card_id = tc.card_id
		 ORDER BY fc.card_id;
		 
		 --get card parameters
		 --specific parameters (defined for a specific group/card/app combo have priority over global parameters defined for a card/app combo)
		 --query might need optimisation or rethinking if parameter numbers ever go into the 100ks
	OPEN out_card_init_param_cur FOR
		 SELECT cip.card_id, cip.key, cip.value
			 FROM card_init_param cip
			   JOIN card_group_card cgc
				  ON cgc.app_sid = cip.app_sid 
			   AND cgc.card_id = cip.card_id 
			   AND (cip.card_group_id IS NULL OR cip.card_group_id = cgc.card_group_id)
		 WHERE cgc.card_group_id = in_card_group_id
			   AND cgc.card_id IN (SELECT DISTINCT COLUMN_VALUE FROM TABLE(in_cards_to_use))
			   AND (cip.param_type_id = chain_pkg.CIPT_SPECIFIC OR cip.card_id NOT IN (
																								SELECT cip.card_id
																									FROM card_init_param cip
																									  JOIN card_group_card cgc
																										 ON cgc.app_sid = cip.app_sid 
																									  AND cgc.card_id = cip.card_id 
																									  AND (cip.card_group_id IS NULL OR cip.card_group_id = cgc.card_group_id)
																								WHERE cgc.card_group_id = in_card_group_id 
																									  AND cgc.card_id IN (SELECT COLUMN_VALUE FROM TABLE(in_cards_to_use))
																									  AND cip.param_type_id = chain_pkg.CIPT_SPECIFIC
						));
						
END;

PROCEDURE GetManagersWithCardsIds (
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	OPEN out_manager_cur FOR 
		SELECT card_group_id FROM card_group 
		 WHERE card_group_id IN (SELECT card_group_id FROM card_group_card WHERE app_sid = security_pkg.getApp);
END;

PROCEDURE SetCardInitParam (
	in_card_id					IN  card.card_id%TYPE,
	in_key							IN VARCHAR2,
	in_value						IN VARCHAR2,	
	in_param_type_id	IN  card_init_param_type.param_type_id%TYPE DEFAULT chain_pkg.CIPT_GLOBAL,	
	in_group_id				IN  card_group.card_group_id%TYPE DEFAULT NULL
) AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetCardInitParams can only be run as BuiltIn/Administrator');
	END IF;
	
	--clear param if null value
	IF in_value IS NULL THEN
			DELETE FROM card_init_param
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND card_id = in_card_id
				   AND param_type_id = in_param_type_id
				   AND key = in_key
				   AND (card_group_id = in_group_id OR card_group_id IS NULL AND in_group_id IS NULL);
		RETURN;
	END IF;
	
	--otherwise add/update param
	BEGIN
		INSERT INTO card_init_param(card_id, app_sid, param_type_id, key, value, card_group_id)
			VALUES(in_card_id, SYS_CONTEXT('SECURITY', 'APP'), in_param_type_id, in_key, in_value, in_group_id);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE card_init_param 
			   SET value = in_value
		     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND card_id = in_card_id
			   AND param_type_id = in_param_type_id
			   AND key = in_key
			   AND (card_group_id = in_group_id OR card_group_id IS NULL AND in_group_id IS NULL);
	END;
	
END;

PROCEDURE SetCardInitParam (
	in_js_class					IN  card.js_class_type%TYPE,
	in_key							IN VARCHAR2,
	in_value						IN VARCHAR2,	
	in_param_type_id	IN  card_init_param_type.param_type_id%TYPE DEFAULT chain_pkg.CIPT_GLOBAL,	
	in_group_name			IN  card_group.name%TYPE DEFAULT NULL
) AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT NULL;
	v_card_id					card.card_id%TYPE DEFAULT GetCardId(in_js_class);
BEGIN
	IF in_group_name IS NOT NULL THEN
		v_group_id := GetCardGroupId(in_group_name);
	END IF;
	
	SetCardInitParam(v_card_id, in_key, in_value, in_param_type_id, v_group_id);
END;

END card_pkg;
/
