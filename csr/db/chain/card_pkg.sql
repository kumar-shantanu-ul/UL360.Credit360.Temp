CREATE OR REPLACE PACKAGE  CHAIN.card_pkg
IS

PROCEDURE GetActiveCards (
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE DumpCard (
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE DumpCards (
	in_js_classes			IN  T_STRING_LIST
);

PROCEDURE DumpGroup (
	in_group_name			IN  card_group.name%TYPE,
	in_host					IN  v$chain_host.host%TYPE
);

PROCEDURE DumpCardsAndGroup (
	in_group_name			IN  card_group.name%TYPE,
	in_host					IN  v$chain_host.host%TYPE
);

FUNCTION GetCardId (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN card.card_id%TYPE;

FUNCTION GetCardGroupId (
	in_group_name			IN  card_group.name%TYPE
) RETURN card_group.card_group_id%TYPE;

PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card_group.description%TYPE,
	in_helper_pkg			IN  card_group.helper_pkg%TYPE DEFAULT NULL,
	in_list_page_url		IN  card_group.list_page_url%TYPE DEFAULT NULL
);

-- this is called DESTROY instead of DELETE to highlight the fact that it potentially
-- removes data across applications - BEWARE!
PROCEDURE DestroyCard (
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE,
	in_progression_actions	IN  T_STRING_LIST
);

PROCEDURE AddProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_action	IN  card_progression_action.action%TYPE
);

PROCEDURE AddProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
);

PROCEDURE RenameProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_from_action 			IN  card_progression_action.action%TYPE,
	in_to_action 			IN  card_progression_action.action%TYPE
);

FUNCTION GetProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN T_STRING_LIST;

PROCEDURE InsertGroupCard (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_type			IN  card.js_class_type%TYPE,
	in_pos					IN	NUMBER DEFAULT 0
);

PROCEDURE RemoveGroupCard (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_type			IN  card.js_class_type%TYPE
);

PROCEDURE SetGroupCards (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_types		IN  T_STRING_LIST
);

PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_to_js_class			IN  card.js_class_type%TYPE
);

PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_action_list			IN  T_CARD_ACTION_LIST
);

PROCEDURE MarkTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE ClearTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
);

PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_card_init_param_cur OUT security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_card_init_param_cur OUT security_pkg.T_OUTPUT_CUR	
);

--temp backwards comp support
PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR
);

-- generally, should not be called directly
PROCEDURE CollectManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	in_cards_to_use			IN  security.T_SID_TABLE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_card_init_param_cur OUT security_pkg.T_OUTPUT_CUR		
);

PROCEDURE GetManagersWithCardsIds (
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCardInitParam (
	in_js_class				IN  card.js_class_type%TYPE,
	in_key					IN VARCHAR2,
	in_value				IN VARCHAR2,	
	in_param_type_id		IN  card_init_param_type.param_type_id%TYPE DEFAULT chain_pkg.CIPT_GLOBAL,	
	in_group_name			IN  card_group.name%TYPE DEFAULT NULL
) ;

PROCEDURE SetCardInitParam (
	in_card_id				IN  card.card_id%TYPE,
	in_key					IN VARCHAR2,
	in_value				IN VARCHAR2,	
	in_param_type_id		IN  card_init_param_type.param_type_id%TYPE DEFAULT chain_pkg.CIPT_GLOBAL,	
	in_group_id				IN  card_group.card_group_id%TYPE DEFAULT NULL
);

END card_pkg;
/

