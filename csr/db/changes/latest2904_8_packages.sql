CREATE OR REPLACE PACKAGE chain.temp_card_pkg
IS

FUNCTION GetCardId (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN card.card_id%TYPE;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE
);
END;
/

CREATE OR REPLACE PACKAGE BODY chain.temp_card_pkg
IS

DEFAULT_ACTION 				CONSTANT VARCHAR2(10) := 'default';

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


PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE
)
AS
	v_card_id				card.card_id%TYPE;
	v_found					BOOLEAN;
BEGIN
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
	

	BEGIN
		INSERT INTO card_progression_action
		(card_id, action)
		VALUES
		(GetCardId(in_js_class), LOWER(TRIM(DEFAULT_ACTION)));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- empty array check
	DELETE FROM card_group_progression
	 WHERE from_card_id = v_card_id
	   AND from_card_action <> DEFAULT_ACTION;
	  
	DELETE FROM card_progression_action
	 WHERE card_id = v_card_id
	   AND action <> DEFAULT_ACTION;
END;

END;
/
