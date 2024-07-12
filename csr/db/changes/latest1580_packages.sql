CREATE OR REPLACE PACKAGE  CHAIN.temp_card_pkg
IS

PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card.description%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE SetGroupCards (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_types		IN  T_STRING_LIST
);

END temp_card_pkg;
/




CREATE OR REPLACE PACKAGE BODY CHAIN.temp_card_pkg
IS

DEFAULT_ACTION 				CONSTANT VARCHAR2(10) := 'default';
-------------------------
--RegisterCardGroup related--
-------------------------
PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card.description%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCardGroup can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO card_group
		(card_group_id, name, description)
		VALUES
		(in_id, in_name, in_description);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE card_group
			   SET name = in_name, 
				   description = in_description
			 WHERE card_group_id = in_id;
	END;	
			
END;

-------------------------
--SetGroupCards related--
-------------------------
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
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetCardGroupId can only be run as BuiltIn/Administrator');
	END IF;
	
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


-------------------------
--RegisterCard related--
-------------------------
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

END temp_card_pkg;
/
