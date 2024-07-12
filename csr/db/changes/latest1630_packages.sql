
CREATE OR REPLACE PACKAGE chain.filter_pkg
IS


DATE_SPECIFIY_DATES				CONSTANT NUMBER(10) := -1;
DATE_IN_THE_LAST_DAY			CONSTANT NUMBER(10) := -2;
DATE_IN_THE_LAST_WEEK			CONSTANT NUMBER(10) := -3;
DATE_IN_THE_LAST_MONTH			CONSTANT NUMBER(10) := -4;
DATE_IN_THE_LAST_THREE_MONTHS	CONSTANT NUMBER(10) := -5;
DATE_IN_THE_LAST_SIX_MONTHS		CONSTANT NUMBER(10) := -6;
DATE_IN_THE_LAST_YEAR			CONSTANT NUMBER(10) := -7;
DATE_IN_THE_PAST				CONSTANT NUMBER(10) := -8;
DATE_IN_THE_FUTURE				CONSTANT NUMBER(10) := -9;
DATE_IN_THE_NEXT_WEEK			CONSTANT NUMBER(10) := -10;
DATE_IN_THE_NEXT_MONTH			CONSTANT NUMBER(10) := -11;
DATE_IN_THE_NEXT_THREE_MONTHS	CONSTANT NUMBER(10) := -12;
DATE_IN_THE_NEXT_SIX_MONTHS		CONSTANT NUMBER(10) := -13;
DATE_IN_THE_NEXT_YEAR			CONSTANT NUMBER(10) := -14;

-- SO PROCS
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
);

-- Session callbacks
PROCEDURE OnSessionMigrated (
	in_old_act_id					IN security_pkg.T_ACT_ID,
	in_new_act_id					IN security_pkg.T_ACT_ID
);

PROCEDURE OnSessionDeleted (
	in_old_act_id					IN security_pkg.T_ACT_ID
);

-- Registering Filters
PROCEDURE CreateFilterType (
	in_description			filter_type.description%TYPE,
	in_helper_pkg			filter_type.helper_pkg%TYPE,
	in_js_class_type		card.js_class_type%TYPE
);

FUNCTION GetFilterTypeId (
	in_js_class_type		card.js_class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE;

-- Starting a filter session
PROCEDURE CheckCompoundFilterAccess (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_access					IN	NUMBER
);

PROCEDURE CreateCompoundFilter (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CreateCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE CopyCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	out_new_compound_filter_id	OUT	compound_filter.compound_filter_id%TYPE
);

PROCEDURE SaveCompoundFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_name						IN	saved_filter.name%TYPE,
	out_saved_filter_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE GetSavedFilters (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_query					IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE LoadSavedFilter (
	in_saved_filter_sid			IN	security_pkg.T_SID_ID,
	out_new_compound_filter_id	OUT	compound_filter.compound_filter_id%TYPE
);

-- Filter item management
FUNCTION GetNextFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_filter_type_id			IN	filter_type.filter_type_id%TYPE
) RETURN NUMBER;

FUNCTION GetCompoundIdFromfilterId (
	in_filter_id			IN	filter.filter_id%TYPE
) RETURN compound_filter.compound_filter_id%TYPE;

PROCEDURE DeleteFilter (
	in_filter_id			IN	filter.filter_id%TYPE
);

PROCEDURE AddCardFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
);

PROCEDURE UpdateFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	in_operator_type			IN	filter.operator_type%TYPE
);

PROCEDURE GetFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
);

PROCEDURE GetFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

-- Filter field + value management. NB this is a generic version for use in helper_pkgs, but helper_pkgs can choose to store this information how they want
PROCEDURE AddFilterField (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_name					IN	filter_field.name%TYPE,
	in_comparator			IN	filter_field.comparator%TYPE,
	out_filter_field_id		OUT	filter_field.filter_field_id%TYPE
);

PROCEDURE DeleteRemainingFields (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_fields_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE AddNumberValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.num_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddRegionValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_region_sid			IN	filter_value.region_sid%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddUserValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_user_sid				IN	filter_value.user_sid%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddStringValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.str_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddDateRangeValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN  filter_value.num_value%TYPE,
	in_start_dtm			IN	filter_value.start_dtm_value%TYPE,
	in_end_dtm				IN	filter_value.end_dtm_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE DeleteRemainingFieldValues (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_values_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE CopyFieldsAndValues (
	in_from_filter_id			IN	filter.filter_id%TYPE,
	in_to_filter_id				IN	filter.filter_id%TYPE
);

PROCEDURE GetFieldValues (
	in_filter_id			IN	filter.filter_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

END filter_pkg;
/


CREATE OR REPLACE PACKAGE BODY chain.filter_pkg
IS

/*********************************************************************************/
/**********************   SO PROCS   *********************************************/
/*********************************************************************************/
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Only require ACLs to lock down this method, or do we?
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS	
BEGIN
	IF in_new_name IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting a name');
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS 
BEGIN
	-- TODO: Can we rely on ACLs here?
	
	-- TODO: Should we add a call to the helper_pkg for deletes?
	-- This will trigger cascade deletes where necessary
	DELETE FROM filter
	 WHERE compound_filter_id IN (
		SELECT compound_filter_id
		  FROM saved_filter
		 WHERE saved_filter_sid = in_sid_id
	);
	
	DELETE FROM compound_filter
	 WHERE compound_filter_id IN (
		SELECT compound_filter_id
		  FROM saved_filter
		 WHERE saved_filter_sid = in_sid_id
	);
	
	DELETE FROM saved_filter
	 WHERE saved_filter_sid = in_sid_id;
	
END;


PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

/**********************************************************************************/
/********************** Session callbacks *****************************************/
/**********************************************************************************/
PROCEDURE OnSessionMigrated (
	in_old_act_id					IN security_pkg.T_ACT_ID,
	in_new_act_id					IN security_pkg.T_ACT_ID
) AS
BEGIN
	UPDATE compound_filter
	   SET act_id = in_new_act_id
	 WHERE act_id = in_old_act_id;
END;

PROCEDURE OnSessionDeleted (
	in_old_act_id					IN security_pkg.T_ACT_ID
) AS
BEGIN
	-- TODO: What security checks can we do to know it's the session tidying up?
	DELETE FROM filter
	 WHERE compound_filter_id IN (
		SELECT compound_filter_id
		  FROM compound_filter
		 WHERE act_id = in_old_act_id
	);
	
	DELETE FROM compound_filter
	 WHERE act_id = in_old_act_id;
END;

/**********************************************************************************/
/********************** Configuration *********************************************/
/**********************************************************************************/

-- Register a filter type in the system
PROCEDURE CreateFilterType (
	in_description			filter_type.description%TYPE,
	in_helper_pkg			filter_type.helper_pkg%TYPE,
	in_js_class_type		card.js_class_type%TYPE
)
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
	v_card_id				card.card_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateFilterType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			filter_type_id_seq.NEXTVAL,
			in_description,
			in_helper_pkg,
			card_pkg.GetCardId(in_js_class_type)
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE filter_type
			   SET description = in_description,
			       helper_pkg = in_helper_pkg
			 WHERE card_id = card_pkg.GetCardId(in_js_class_type);
	END;
END;

FUNCTION GetFilterTypeId (
	in_js_class_type		card.js_class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
BEGIN
	SELECT filter_type_id
	  INTO v_filter_type_id
	  FROM filter_type
	 WHERE card_id = card_pkg.GetCardId(in_js_class_type);
	
	RETURN v_filter_type_id;
END;

FUNCTION GetFilterTypeId (
	in_card_group_id	card_group.card_group_id%TYPE,
	in_class_type		card.class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
BEGIN
	-- TODO: What if there is more than one? i.e. 2 JS class types sharing 1 C# class type for one card group
	--       This would break, but there's no other way of distinguising filter_type_id from C#
	SELECT filter_type_id
	  INTO v_filter_type_id
	  FROM filter_type
	 WHERE card_id IN (
		SELECT c.card_id
		  FROM card_group_card cgc
		  JOIN card c ON cgc.card_id = c.card_id
		 WHERE cgc.app_sid = security_pkg.GetApp
		   AND cgc.card_group_id = in_card_group_id
		   AND c.class_type = in_class_type);
	
	RETURN v_filter_type_id;
END;

/**********************************************************************************/
/********************** Building up a Filter **************************************/
/**********************************************************************************/

PROCEDURE CheckCompoundFilterAccess (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_access					IN	NUMBER
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_saved_filter_sid			security_pkg.T_SID_ID;
BEGIN
	
	IF NVL(in_compound_filter_id, 0) != 0 THEN
	
		SELECT cf.act_id, sf.saved_filter_sid
		  INTO v_act_id, v_saved_filter_sid
		  FROM compound_filter cf
		  LEFT JOIN saved_filter sf ON cf.compound_filter_id = sf.compound_filter_id
		 WHERE cf.compound_filter_id = in_compound_filter_id;
		
		IF v_act_id IS NULL AND v_saved_filter_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on compound filter with id: '||in_compound_filter_id);
		END IF;
		
		IF v_act_id IS NOT NULL AND v_act_id != security_pkg.GetAct THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on compound filter with id: '||in_compound_filter_id);
		END IF;
		
		IF v_saved_filter_sid IS NOT NULL AND NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_saved_filter_sid, in_access) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on compound filter with id: '||in_compound_filter_id);
		END IF;
	
	END IF;
	
END;

PROCEDURE CreateCompoundFilter (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	CreateCompoundFilter(security_pkg.GetAct, in_card_group_id, out_compound_filter_id);
END;

PROCEDURE CreateCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_compound_filter_id		OUT	compound_filter.compound_filter_id%TYPE
)
AS
BEGIN
	IF in_act_id IS NOT NULL AND in_act_id != security_pkg.GetAct THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_act_id must be NULL or the ACT of the logged on user');
	END IF;
	
	INSERT INTO compound_filter (compound_filter_id, card_group_id, act_id)
	VALUES (compound_filter_id_seq.NEXTVAL, in_card_group_id, in_act_id)
	RETURNING compound_filter_id INTO out_compound_filter_id;
	
	IF in_act_id IS NOT NULL THEN
		security.session_pkg.RegisterCallbacks(in_act_id, 'begin chain.filter_pkg.OnSessionDeleted(:1); end;', 'begin chain.filter_pkg.OnSessionMigrated(:1, :2); end;');
	END IF;
END;

PROCEDURE CopyCompoundFilter (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	out_new_compound_filter_id	OUT	compound_filter.compound_filter_id%TYPE
)
AS
	v_card_group_id				card_group.card_group_id%TYPE;
	v_filter_id					filter.filter_id%TYPE;
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);
	
	SELECT card_group_id
	  INTO v_card_group_id
	  FROM compound_filter
	 WHERE app_sid = security_pkg.GetApp
	   AND compound_filter_id = in_compound_filter_id;
	
	CreateCompoundFilter(in_act_id, v_card_group_id, out_new_compound_filter_id);
	
	FOR r IN (
		SELECT f.filter_id, f.filter_type_id, operator_type, ft.helper_pkg
		  FROM filter f
		  JOIN v$filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_id = in_compound_filter_id
	) LOOP
		INSERT INTO filter (filter_id, filter_type_id, compound_filter_id, operator_type)
		VALUES (filter_id_seq.NEXTVAL, r.filter_type_id, out_new_compound_filter_id, r.operator_type)
		RETURNING filter_id INTO v_filter_id;
		
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.CopyFilter(:from_filter_id, :to_filter_id);END;') USING r.filter_id, v_filter_id;
	END LOOP;
END;

PROCEDURE SaveCompoundFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_name						IN	saved_filter.name%TYPE,
	out_saved_filter_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_parent_sid				security_pkg.T_SID_ID;
	v_card_group_id				card_group.card_group_id%TYPE;
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
BEGIN
	-- security check done by CreateSO
	SELECT card_group_id
	  INTO v_card_group_id
	  FROM compound_filter
	 WHERE app_sid = security_pkg.GetApp
	   AND compound_filter_id = in_compound_filter_id;
	
	IF v_card_group_id IN (24, 25) THEN
		v_parent_sid := security_pkg.GetSid; -- for survey responses / issues, create under user for now
	ELSE
		v_parent_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, company_pkg.GetCompany, chain_pkg.COMPANY_FILTERS);
	END IF;
	
	-- TODO: should we set the SO name here?
	SecurableObject_pkg.CreateSO(
		security_pkg.GetAct, v_parent_sid, 
		class_pkg.GetClassID('ChainCompoundFilter'), NULL, out_saved_filter_sid);
	
	-- Temporarily set act to current act for new compound filter so copying security checks pass
	CopyCompoundFilter(security_pkg.GetAct, in_compound_filter_id, v_compound_filter_id);
	
	INSERT INTO saved_filter (saved_filter_sid, compound_filter_id, name)
	VALUES (out_saved_filter_sid, v_compound_filter_id, in_name);
	
	-- Remove act on saved filter
	UPDATE compound_filter
	   SET act_id = NULL
	 WHERE compound_filter_id = v_compound_filter_id;
END;

PROCEDURE GetSavedFilters (
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	in_query					IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
BEGIN
	IF in_card_group_id IN (24, 25) THEN
		v_parent_sid := security_pkg.GetSid; -- for survey responses / issues, create under user for now
	ELSE
		v_parent_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, company_pkg.GetCompany, chain_pkg.COMPANY_FILTERS);
	END IF;
	
	-- trim results based on security
	OPEN out_cur FOR
		SELECT sf.saved_filter_sid, sf.name
		  FROM saved_filter sf
		  JOIN compound_filter cf ON sf.compound_filter_id = cf.compound_filter_id
		  JOIN TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), 
				v_parent_sid, security_pkg.PERMISSION_READ)) so ON sf.saved_filter_sid = so.sid_id
		 WHERE LOWER(sf.name) LIKE NVL(LOWER(in_query), '')||'%'
		   AND cf.card_group_id = in_card_group_id
		 ORDER BY LOWER(sf.name);
END;

PROCEDURE LoadSavedFilter (
	in_saved_filter_sid			IN	security_pkg.T_SID_ID,
	out_new_compound_filter_id	OUT	compound_filter.compound_filter_id%TYPE
)
AS
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
BEGIN
	-- CopyCompoundFilter does security checks
	SELECT compound_filter_id
	  INTO v_compound_filter_id
	  FROM saved_filter
	 WHERE saved_filter_sid = in_saved_filter_sid;
	
	CopyCompoundFilter(security_pkg.GetAct, v_compound_filter_id, out_new_compound_filter_id);
END;

FUNCTION GetNextFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_filter_type_id			IN	filter_type.filter_type_id%TYPE
) RETURN NUMBER
AS
	v_filter_id					filter.filter_id%TYPE;
BEGIN
	INSERT INTO filter (filter_id, filter_type_id, compound_filter_id)
	VALUES (filter_id_seq.NEXTVAL, in_filter_type_id, in_compound_filter_id)
	RETURNING filter_id INTO v_filter_id;
	
	RETURN v_filter_id;
END;

FUNCTION GetCompoundIdFromFilterId (
	in_filter_id			IN	filter.filter_id%TYPE
) RETURN compound_filter.compound_filter_id%TYPE
AS
	v_compound_filter_id		compound_filter.compound_filter_id%TYPE;
BEGIN
	SELECT compound_filter_id
	  INTO v_compound_filter_id
	  FROM filter
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;
	
	RETURN v_compound_filter_id;
END;

FUNCTION GetCompoundIdFromFieldId (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE
) RETURN compound_filter.compound_filter_id%TYPE
AS
	v_filter_id				filter.filter_id%TYPE;
BEGIN
	SELECT filter_id
	  INTO v_filter_id
	  FROM filter_field
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_field_id = in_filter_field_id;
	
	RETURN GetCompoundIdFromFilterId(v_filter_id);
END;

PROCEDURE DeleteFilter (
	in_filter_id				IN	filter.filter_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	-- Currently have cascading deletes on this table, but maybe this should be handled by the helper_pkg?
	DELETE FROM filter
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;
END;

PROCEDURE AddCardFilter (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_WRITE);
	
	out_filter_id := GetNextFilterId(in_compound_filter_id, GetFilterTypeId(in_card_group_id, in_class_type));
END;

PROCEDURE UpdateFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	in_operator_type			IN	filter.operator_type%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	UPDATE filter
	   SET operator_type = in_operator_type
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;
END;

PROCEDURE GetFilterId (
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
)
AS
	v_filter_type_id			filter_type.filter_type_id%TYPE := GetFilterTypeId(in_card_group_id, in_class_type);
BEGIN
	CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);
	
	BEGIN
		SELECT filter_id
		  INTO out_filter_id
		  FROM filter
		 WHERE app_sid = security_pkg.GetApp
		   AND compound_filter_id = in_compound_filter_id
		   AND filter_type_id = v_filter_type_id;
	EXCEPTION WHEN no_data_found THEN
		out_filter_id := 0;
	END;
END;

PROCEDURE GetFilter (
	in_filter_id				IN	filter.filter_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT filter_id, filter_type_id, compound_filter_id, operator_type
		  FROM filter
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id;
END;


/**********************************************************************************/
/**********************   Filter Field/Value management   *************************/
/**********************************************************************************/
PROCEDURE AddFilterField (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_name					IN	filter_field.name%TYPE,
	in_comparator			IN	filter_field.comparator%TYPE,
	out_filter_field_id		OUT	filter_field.filter_field_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_field (filter_field_id, filter_id, name, comparator)
	VALUES (filter_field_id_seq.NEXTVAL, in_filter_id, in_name, in_comparator)
	RETURNING filter_field_id INTO out_filter_field_id;
END;

PROCEDURE DeleteRemainingFields (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_fields_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_fields_to_keep		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_fields_to_keep);
	v_count					NUMBER(10);
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);
	
	DELETE FROM filter_field
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id
	   AND filter_field_id NOT IN (
		SELECT item FROM TABLE(v_fields_to_keep));
END;

PROCEDURE AddNumberValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.num_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, num_value)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_value)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddRegionValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_region_sid			IN	filter_value.region_sid%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, region_sid)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_region_sid)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddUserValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_user_sid				IN	filter_value.user_sid%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, user_sid)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_user_sid)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddStringValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.str_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, str_value)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_value)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddDateRangeValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN  filter_value.num_value%TYPE,
	in_start_dtm			IN	filter_value.start_dtm_value%TYPE,
	in_end_dtm				IN	filter_value.end_dtm_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, start_dtm_value, end_dtm_value)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_value, in_start_dtm, in_end_dtm)
	RETURNING filter_value_id INTO out_filter_value_id;
END;

PROCEDURE DeleteRemainingFieldValues (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_values_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_values_to_keep		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_values_to_keep);
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE);
	
	DELETE FROM filter_value
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_field_id = in_filter_field_id
	   AND filter_value_id NOT IN (
		SELECT item FROM TABLE(v_values_to_keep));
END;

PROCEDURE CopyFieldsAndValues (
	in_from_filter_id			IN	filter.filter_id%TYPE,
	in_to_filter_id				IN	filter.filter_id%TYPE
)
AS
	v_filter_field_id 			filter_field.filter_field_id%TYPE;
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_from_filter_id), security_pkg.PERMISSION_READ);
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_to_filter_id), security_pkg.PERMISSION_WRITE);
	
	FOR r IN (
		SELECT filter_field_id, name, comparator
		  FROM filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_from_filter_id
	) LOOP
		INSERT INTO filter_field (filter_field_id, filter_id, name, comparator)
		VALUES (filter_field_id_seq.NEXTVAL, in_to_filter_id, r.name, r.comparator)
		RETURNING filter_field_id INTO v_filter_field_id;
		
		INSERT INTO filter_value (filter_value_id, filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid)
		SELECT filter_value_id_seq.NEXTVAL, v_filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid
		  FROM filter_value
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_field_id = r.filter_field_id;
	END LOOP;
END;


PROCEDURE GetFieldValues (
	in_filter_id			IN	filter.filter_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckCompoundFilterAccess(GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT app_sid, filter_id, filter_field_id, name, filter_value_id, str_value, num_value, start_dtm_value, end_dtm_value, region_sid, description, user_sid
		  FROM v$filter_value
		 WHERE filter_id = in_filter_id;
END;


END filter_pkg;
/