-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=3
@update_header

-- SECURITY
declare
	v_ver number;
begin
	select db_version into v_ver from security.version;
	if v_ver NOT IN (52, 53) then
		raise_application_error(-20001, 'Security schema is not version 52 or 53');
	end if;
end;
/

declare
	v_cnt number;
begin
	select count(*) into v_cnt from all_tables where owner='SECURITY' and table_name='SECURABLE_OBJECT_DESCRIPTION';
	if v_cnt = 0 then
		execute immediate '
CREATE TABLE security.securable_object_description (
 SID_ID              NUMBER(10)          NOT NULL,
 LANG                VARCHAR2(10)        NOT NULL,
 DESCRIPTION         VARCHAR2(1023)      NOT NULL,
 CONSTRAINT pk_securable_object_desc PRIMARY KEY (SID_ID, LANG),
 CONSTRAINT fk_so_desc_sid FOREIGN KEY (SID_ID) REFERENCES security.securable_object (SID_ID) ON DELETE CASCADE
)';
		execute immediate 'GRANT SELECT ON security.securable_object_description TO csr';
	end if;
end;
/

-- SO
DROP TYPE SECURITY.T_SO_TABLE;

CREATE OR REPLACE TYPE SECURITY.T_SO_ROW AS 
	OBJECT ( 
		sid_id 			NUMBER(10,0),
		parent_sid_id 	NUMBER(10,0),
		dacl_id 		NUMBER(10,0),
		class_id 		NUMBER(10,0),
		NAME 			VARCHAR2(255),
		flags 			NUMBER(10,0),
		owner 			NUMBER(10,0) ,
		description		VARCHAR2(4000)
	);
/
GRANT EXECUTE ON SECURITY.T_SO_ROW TO PUBLIC;
	
CREATE OR REPLACE TYPE SECURITY.T_SO_TABLE AS 
	TABLE OF SECURITY.T_SO_ROW;
/

GRANT EXECUTE ON SECURITY.T_SO_TABLE TO PUBLIC;

-- SO DESCENDANTS

DROP TYPE SECURITY.T_SO_DESCENDANTS_TABLE;

CREATE OR REPLACE TYPE SECURITY.T_SO_DESCENDANTS_ROW AS
	OBJECT ( 
		sid_id 			NUMBER(10,0),
		parent_sid_id 	NUMBER(10,0),
		dacl_id 		NUMBER(10,0),
		class_id 		NUMBER(10,0),
		NAME 			VARCHAR2(255),
		flags 			NUMBER(10,0),
		owner 			NUMBER(10,0),
		so_level		NUMBER(10,0),
		is_leaf			NUMBER(1),
		description		VARCHAR2(4000)
	);
/
GRANT EXECUTE ON SECURITY.T_SO_DESCENDANTS_ROW TO PUBLIC;

CREATE OR REPLACE TYPE SECURITY.T_SO_DESCENDANTS_TABLE AS
	TABLE OF SECURITY.T_SO_DESCENDANTS_ROW;
/

GRANT EXECUTE ON SECURITY.T_SO_DESCENDANTS_TABLE TO PUBLIC;

-- SO TREE

DROP TYPE SECURITY.T_SO_TREE_TABLE;
	
CREATE OR REPLACE TYPE SECURITY.T_SO_TREE_ROW AS
	OBJECT ( 
		sid_id 			NUMBER(10,0),
		parent_sid_id 	NUMBER(10,0),
		dacl_id 		NUMBER(10,0),
		class_id 		NUMBER(10,0),
		NAME 			VARCHAR2(255),
		flags 			NUMBER(10,0),
		owner 			NUMBER(10,0),
		so_level		NUMBER(10,0),
		is_leaf			NUMBER(1),
		path			VARCHAR2(4000), -- can do 32767 but then we can't grant execute...
		description		VARCHAR2(4000)
	);
/
GRANT EXECUTE ON SECURITY.T_SO_TREE_ROW TO PUBLIC;

CREATE OR REPLACE TYPE SECURITY.T_SO_TREE_TABLE AS
	TABLE OF SECURITY.T_SO_TREE_ROW;
/

GRANT EXECUTE ON SECURITY.T_SO_TREE_TABLE TO PUBLIC;

--@..\securableobject_pkg
CREATE OR REPLACE PACKAGE SECURITY.Securableobject_Pkg IS

/** 
 * Find an object from the given path
 * 
 * @param in_act		Access token.
 * @param in_sid_id		The sid of the object
 * @param in_path		The path to the object
 */
FUNCTION GetSIDFromPath(
	in_act				IN Security_Pkg.T_ACT_ID,
	in_parent_sid_id	IN Security_Pkg.T_SID_ID,
	in_path				IN VARCHAR2
) RETURN Security_Pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetSIDFromPath, WNDS, WNPS);


/**
 * Read all attributes of a securable object.  You need to be
 * careful to observe the rules for attribute inheritance when using this.
 * 	
 * The output rowset is in the form:
 * attribute_id, class_id, attribute_name, attribute_flags, string_value, number_value, date_value, blob_value, isobject, clob_value
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 * @param out_cursor	The attributes rowset.
 */
PROCEDURE ReadAttributes(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(ReadAttributes, WNDS, WNPS);


/** 
 * Return the name of a securable object from its sid.
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
FUNCTION GetName(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN Security_Pkg.T_SO_NAME;
PRAGMA RESTRICT_REFERENCES(GetName, WNDS, WNPS);


/** 
 * Remove the named attribute from the given securable object
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_name		The name of the attribute
 */
PROCEDURE DeleteNamedAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
);


/** 
 * Remove the given attribute from the given securable object
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id		The id of the attribute
 */
PROCEDURE DeleteAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
);


/**
 * Return a named attribute of string type from the object.
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_attribute_name The name of the attribte
 * @return					The attribute
 */
FUNCTION GetNamedStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_SO_ATTRIBUTE_STRING;
PRAGMA RESTRICT_REFERENCES(GetNamedStringAttribute, WNDS, WNPS);


/**
 * Return an attribute by attribute ID from the object.
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_attribute_name The name of the attribte
 * @return					The attribute
 */
FUNCTION GetStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
) RETURN Security_Pkg.T_SO_ATTRIBUTE_STRING;
PRAGMA RESTRICT_REFERENCES(GetStringAttribute, WNDS, WNPS);


/**
 * Set a named attribute on the object.
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id	 	The id of the attribute
 * @param in_attribute_value	The value of the attribute
 */
PROCEDURE SetNamedStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_STRING
);


/**
 * Set an attribute by attribute ID on the object.
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id	 	The id of the attribute
 * @param in_attribute_value	The value of the attribute
 */
PROCEDURE SetStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_STRING
);


/**
 * Return a named attribute of date type from the object.
 *
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_attribute_name	The name of the attribte
 * @return					The attribute
 */
FUNCTION GetNamedDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_SO_ATTRIBUTE_DATE;
PRAGMA RESTRICT_REFERENCES(GetNamedDateAttribute, WNDS, WNPS);


/** 
 * Return an attribute by attribute ID from the object.
 *
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_attribute_name The name of the attribte
 * @return					The attribute
 */
FUNCTION GetDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
) RETURN Security_Pkg.T_SO_ATTRIBUTE_DATE;
PRAGMA RESTRICT_REFERENCES(GetDateAttribute, WNDS, WNPS);


/**
 * Set a named attribute on the object.
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id	 	The id of the attribute
 * @param in_attribute_value	The value of the attribute
 */
PROCEDURE SetNamedDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_DATE
);


/**
 * Set an attribute by attribute ID on the object.
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id	 	The id of the attribute
 * @param in_attribute_value	The value of the attribute
 */
PROCEDURE SetDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_DATE
);


/** 
 * Return a named attribute of number type from the object.
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_attribute_name The name of the attribte
 * @return					The attribute
 */
FUNCTION GetNamedNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_SO_ATTRIBUTE_NUMBER;
PRAGMA RESTRICT_REFERENCES(GetNamedNumberAttribute, WNDS, WNPS);


/**
 * Return an attribute by attribute ID from the object.
 *
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_name		The name of the attribte
 * @return						The attribute
 */
FUNCTION GetNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
) RETURN Security_Pkg.T_SO_ATTRIBUTE_NUMBER;
PRAGMA RESTRICT_REFERENCES(GetNumberAttribute, WNDS, WNPS);


/**
 * Set a named attribute on the object.
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id	 	The id of the attribute
 * @param in_attribute_value	The value of the attribute
 */
PROCEDURE SetNamedNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_NUMBER
);


/**
 * Set an attribute by attribute ID on the object.
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_attribute_id	 	The id of the attribute
 * @param in_attribute_value	The value of the attribute
 */
PROCEDURE SetNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_NUMBER
);


/** 
 * Create a new securable object.
 *
 * @param in_act_id				Access token
 * @param in_parent_sid			The sid of the parent object
 * @param in_object_class_id	The class of the new object
 * @param in_object_name		The name of the new object
 * @param out_sid_id			The sid of the created object.
 */
PROCEDURE CreateSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_parent_sid		IN Security_Pkg.T_SID_ID,
	in_object_class_id  IN Security_Pkg.T_CLASS_ID,
	in_object_name		IN Security_Pkg.T_SO_NAME,
	out_sid_id			OUT Security_Pkg.T_SID_ID
);

/** 
 * Delete a securable object.
 *
 * @param in_act_id Access token
 * @param in_sid_id The sid of the object
 */
PROCEDURE DeleteSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
);

/** 
 * Move a securable object.
 *
 * @param in_act_id Access token
 * @param in_sid_id The sid of the object
 * @param in_new_parent_sid_id The sid of the new parent
 */
PROCEDURE MoveSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_parent_sid	IN Security_Pkg.T_SID_ID
);

PROCEDURE MoveSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_parent_sid	IN Security_Pkg.T_SID_ID,
	in_overwrite		IN NUMBER
);

/** 
 * Rename a securable object.
 *
 * @param in_act_id Access token
 * @param in_sid_id The sid of the object
 * @param in_object_name The new name of the object
 */
PROCEDURE RenameSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_object_name		IN Security_Pkg.T_SO_NAME
);

/**
 * Take ownership of a securable object.  The user or group
 * sid must be in your ACT to do this.
 *
 * @param in_act_id Access token
 * @param in_sid_id The sid of the object
 * @param in_new_owner_sid_id The new owner of the object.
 */
PROCEDURE TakeOwnership(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_owner_sid_id IN Security_Pkg.T_SID_ID
);

/**
 * Take ownership of a securable object and all its children.  
 * The user or group sid must be in your ACT to do this.
 *
 * @param in_act_id Access token
 * @param in_sid_id The sid of the object
 * @param in_new_owner_sid_id The new owner of the object.
 */
PROCEDURE TakeOwnershipRecursive(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_owner_sid_id IN Security_Pkg.T_SID_ID
);

/**
 * Return details of a securable object as a rowset in the format:
 *
 * The rowset is of the fixed form:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 *
 * This rowset may not be modified.  All functions returning rowsets
 * with securable object details are of this format.
 *
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 * @param out_cursor	The details
 */
PROCEDURE GetSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetSO, WNDS, WNPS);

/**
 * Return details of a securable object as a so_row object in the format:
 *
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 *
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
FUNCTION GetSOAsRowObject(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_ROW;
PRAGMA RESTRICT_REFERENCES(GetSOAsRowObject, WNDS);

/** 
 * Set the flags of a securable object.
 *
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param in_flags		The object's flags
 */
PROCEDURE SetFlags(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_flags			IN Security_Pkg.T_SO_FLAGS
);


/**
 * Set a single flag of a securable object.
 *
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param in_flag		The flag to set.
 *
 */
PROCEDURE SetFlag(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_flag				IN Security_Pkg.T_SO_FLAGS
);


/**
 * Clear a flag of a securable object.
 *
 *	@param in_act_id	Access token.
 *	@param in_sid_id	The sid of the object
 *	@param in_flags		The flag to clear
 */
PROCEDURE ClearFlag(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_flag				IN Security_Pkg.T_SO_FLAGS
);


/**
 * Return the sid of the parent of the securable object
 *	
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @return				The sid of the parent
 */
FUNCTION GetParent(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN Security_Pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetParent, WNDS, WNPS);



/**
 * Return all the parents of a securable object in tree form.
 *	
 * The rowset is of the fixed form:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 * 
 * This rowset may not be modified.  All functions returning rowsets
 * with securable object details are of this format.
 * 
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param out_cursor	The rowset containing the details
 */
PROCEDURE GetParents(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
);


/**
 * Return all the parents of a securable object in tree form.
 *	
 * The returned table is of the from:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 * 
 * All functions returning tables with securable object details are 
 * of this format.
 * 
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 */
FUNCTION GetParentsAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_TABLE;

/**
 * List all next level children of the securable object.
 * 
 * The rowset is of the fixed form:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 * 
 * This rowset may not be modified.  All functions returning rowsets
 * with securable object details are of this format.
 * 
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param out_cursor	The rowset containing the details
 */    
PROCEDURE GetChildren(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetChildren, WNDS, WNPS);


/**
 * List all next level children of the securable object.
 * 
 * The table is of the fixed form SO_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 * 
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param out_table		Table object containing the details
 */   
FUNCTION GetChildrenAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID)
RETURN T_SO_TABLE;
PRAGMA RESTRICT_REFERENCES(GetChildrenAsTable, WNDS, WNPS);

/**
 * Given a list of SIDs, then check all of them for the given permission
 * and return a table of SOs that permission is granted on
 * 
 * @param in_act_id			Access token.
 * @param in_sids			Table of SIDs to check
 * @param in_permission_set	Permissions to check for
 * @return					Table object containing the details
 */   
FUNCTION GetSIDsWithPermAsTable(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sids				IN	security.T_SID_TABLE,
	in_permission_set	IN 	security_pkg.T_PERMISSION
) RETURN T_SO_TABLE;
PRAGMA RESTRICT_REFERENCES(GetSIDsWithPermAsTable, WNDS, WNPS);

/**
 * Given a list of SIDs, then check all of them for the given permission
 * and return a the SOs that permission is granted on
 * 
 * @param in_act_id			Access token.
 * @param in_sids			Table of SIDs to check
 * @param in_permission_set	Permissions to check for
 * @param out_cur			Rowset containing securable object details
 */   
PROCEDURE GetSIDsWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sids				IN	security.T_SID_TABLE,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Given a list of SIDs, then check all of them for the given permission
 * and return a the SOs that permission is granted on
 * 
 * @param in_act_id			Access token.
 * @param in_sids			Table of SIDs to check
 * @param in_permission_set	Permissions to check for
 * @param out_cur			Rowset containing securable object details
 */   
PROCEDURE GetSIDsWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sids				IN	security_pkg.T_SID_IDS,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * As #GetChildrenWithPerm but returns a table object.
 * 
 * @param in_act_id			Access token.
 * @param in_sid_id			The sid of the object
 * @param in_permission_set	Permissions to check for
 * @return					Table object containing the details
 */   
FUNCTION GetChildrenWithPermAsTable(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION
) RETURN T_SO_TABLE;
PRAGMA RESTRICT_REFERENCES(GetChildrenWithPermAsTable, WNDS, WNPS);


/**
 * List all next level children of the securable object that the caller
 * has the given permission on.
 * 
 * The table is of the fixed form SO_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER
 * 
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param out_table		Table object containing the details
 */   
PROCEDURE GetChildrenWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetChildrenWithPerm, WNDS, WNPS);


/**
 * List descendants of the securable object 
 * 
 * The table is of the fixed form T_SO_DESCENDANTS_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SO_LEVEL
 * 
 * @param in_act_id		Access token.
 * @param in_sid_id		The sid of the object
 * @param out_cursor	The output rowset
 */   
PROCEDURE GetDescendants(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetDescendants, WNDS, WNPS);


/**
 * List descendants of the securable object 
 * 
 * The table is of the fixed form T_SO_DESCENDANTS_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SO_LEVEL
 * 
 * @param in_act_id			Access token.
 * @param in_sid_id			The sid of the object
 * @return					The table containing the details
 */   
FUNCTION GetDescendantsAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_DESCENDANTS_TABLE;
PRAGMA RESTRICT_REFERENCES(GetDescendantsAsTable, WNDS, WNPS);


/**
 * List all next level descendants of the securable object that the caller
 * has the given permission on.
 * 
 * The table is of the fixed form T_SO_DESCENDANTS_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SO_LEVEL
 * 
 * @param in_act_id			Access token.
 * @param in_sid_id			The sid of the object
 * @param in_permission_set	The permission to check for
 * @return					Table object containing the details
 */   
FUNCTION GetDescendantsWithPermAsTable(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION
) RETURN T_SO_DESCENDANTS_TABLE;
PRAGMA RESTRICT_REFERENCES(GetDescendantsWithPermAsTable, WNDS, WNPS);


/**
 * List all next level descendants of the securable object that the caller
 * has the given permission on.
 * 
 * The table is of the fixed form T_SO_TREE_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SO_LEVEL, PATH
 * 
 * @param in_act_id			Access token.
 * @param in_sid_id			The sid of the object
 * @param in_permission_set	The permission to check for
 * @param out_cur			Output rowset 
 */   
PROCEDURE GetDescendantsWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetDescendantsWithPerm, WNDS, WNPS);


/**
 * List the tree starting with the given securable object only
 * including nodes that the caller has the given permission on.
 * 
 * The table is of the fixed form T_SO_TREE_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SO_LEVEL, PATH
 * 
 * @param in_act_id			Access token.
 * @param in_sid_id			The sid of the object
 * @param in_permission_set	The permission to check for
 * @param in_fetch_depth	Maximum depth of the tree to fetch (null for no maximum)
 * @return					Table object containing the details
 */
FUNCTION GetTreeWithPermAsTable(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	in_fetch_depth		IN	NUMBER DEFAULT NULL,
	in_limit			IN	NUMBER DEFAULT NULL,
	in_hide_root		IN	NUMBER DEFAULT 0	
)
RETURN T_SO_TREE_TABLE;
PRAGMA RESTRICT_REFERENCES(GetTreeWithPermAsTable, WNDS, WNPS);

/**
 * List the tree starting with the given securable object only
 * including nodes that the caller has the given permission on.
 * 
 * The output rowset is of the fixed form T_SO_DESCENDANTS_ROW:
 * SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SO_LEVEL
 * 
 * @param in_act_id			Access token.
 * @param in_sid_id			The sid of the object
 * @param in_permission_set	The permission to check for
 * @param in_fetch_depth	Maximum depth of the tree to fetch (null for no maximum)
 * @param out_cur			Output rowset 
 */
PROCEDURE GetTreeWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	in_fetch_depth		IN	NUMBER DEFAULT NULL,
	in_limit			IN	NUMBER DEFAULT NULL,	
	in_hide_root		IN	NUMBER DEFAULT 0,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetTreeWithPerm, WNDS, WNPS);

/**
 * Return a table of the ACL keys that the caller
 * has the given permission on.
 * 
 * The table is of the fixed form:
 * KEY_ID
 * 
 * @param in_act_id			Access token.
 * @parma in_object_sid_id	The sid of the object
 * @param in_permission_set	The permission to test for
 * @param in_fetch_depth	Maximum depth of the tree to fetch
 * @return					The table
 */   
FUNCTION GetACLKeysWithPermAsTable(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_permission_set		IN 	security_pkg.T_PERMISSION
) RETURN T_KEYED_ACL_TABLE;
PRAGMA RESTRICT_REFERENCES(GetACLKeysWithPermAsTable, WNDS, WNPS);


/**
 * Return a cursor of the ACL keys that the caller
 * has the given permission on.
 * 
 * The table is of the fixed form:
 * KEY_ID
 * 
 * @param in_act_id			Access token.
 * @parma in_object_sid_id	The sid of the object
 * @param in_permission_set	The permission to test for
 * @param out_cur			The output cursor
 */   
PROCEDURE GetACLKeysWithPerm(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_permission_set		IN 	security_pkg.T_PERMISSION,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetACLKeysWithPerm, WNDS, WNPS);


/**
 * Add a new keyed ACL.  Requires write permission on the object.
 * 
 * @param in_act_id			Access token.
 * @parma in_object_sid_id	The sid of the object
 * @param in_key_id			The key to add
 * @param in_acl_id			The acl to add
 */   
PROCEDURE AddKeyedACL(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_key_id				IN	security_pkg.T_SID_ID,
	in_acl_id				IN	security_pkg.T_ACL_ID
);


/**
 * Remove a keyed ACL.  Requires write permission on the object.
 * Also deletes the ACL itself.
 * 
 * @param in_act_id			Access token.
 * @parma in_object_sid_id	The sid of the object
 * @param in_key_id			The key to add
 */   
PROCEDURE RemoveKeyedACL(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_key_id				IN	security_pkg.T_SID_ID
);


/**
 * Return all keyed ACLs.
 * 
 * The output rowset is in the form:
 * key_id, acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set
 *
 * @param in_act_id			Access token.
 * @parma in_object_sid_id	The sid of the object
 * @param out_cur			Output cursor.
 */   
PROCEDURE GetKeyedACLs(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);
PRAGMA RESTRICT_REFERENCES(GetKeyedACLs, WNDS, WNPS);


/**
 * Returns the full path of a securable object.
 * 	
 * @param in_act_id Access token
 * @param in_sid_id The sid of the object
 * @return A string containing the full path of the object
 */
FUNCTION GetPathFromSID(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id 			IN Security_Pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetPathFromSID, WNDS, WNPS);

/**
 * Upserts a description for a securable object in the given language
 * 	
 * @param in_sid_id 		The sid of the object
 * @param in_lang			The language
 * @param in_description	The new description
 */
PROCEDURE UpsertDescription(
	in_act_id			IN  security_Pkg.T_ACT_ID,
	in_sid_id			IN	securable_object_description.sid_id%TYPE,
	in_lang				IN	securable_object_description.lang%TYPE,
	in_description		IN	securable_object_description.description%TYPE
);

END Securableobject_Pkg;
/
--@..\securableobject_body
CREATE OR REPLACE PACKAGE BODY SECURITY.Securableobject_Pkg IS

FUNCTION GetSIDFromPath(
	in_act				IN Security_Pkg.T_ACT_ID,
	in_parent_sid_id	IN Security_Pkg.T_SID_ID,
	in_path				IN VARCHAR2
) RETURN Security_Pkg.T_SID_ID
AS
	v_parent_sid_id Security_Pkg.T_SID_ID;
	v_path VARCHAR2(4000);
	v_sid_id Security_Pkg.T_SID_ID;
	v_sep_pos NUMBER;
	v_level_name VARCHAR2(4000);
BEGIN
	-- security_pkg paths are case-insensitive (but with case-preservation in names)
	v_path := LOWER(in_path);
	v_parent_sid_id := in_parent_sid_id;
	-- Repeat for each component in the path
	LOOP
		-- Compress /s to nothing
		LOOP
			-- Stop now if we run out of path components
			IF v_path IS NULL THEN
				RETURN v_parent_sid_id;
			END IF;
			IF SUBSTR(v_path, 1, 1) <> '/' THEN
			   EXIT;
			END IF;
			v_path := SUBSTR(v_path, 2);
		END LOOP;
		-- Split out the name of the object at the current level
		v_sep_pos := INSTR(v_path, '/');
		-- if no /s left, the whole string is the object name
		IF v_sep_pos = 0 THEN
			v_level_name := v_path;
		-- otherwise, chop out up to the slash
		ELSE
			v_level_name := SUBSTR(v_path, 1, v_sep_pos - 1);
			v_path := SUBSTR(v_path, v_sep_pos + 1);
		END IF;

		BEGIN
			SELECT NVL(link_sid_id, sid_id) INTO v_sid_id
			  FROM SECURABLE_OBJECT
			 WHERE LOWER(NAME) = v_level_name
			   AND parent_sid_id = v_parent_sid_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_sid_id := NULL;
		END;
		-- If we have run out of path components, or we didn't
		-- find a component with the given name at this level, return
		IF v_sep_pos = 0 OR v_sid_id IS NULL THEN
			EXIT;
		END IF;
		-- Loop around for the next level, this level because the parent
		v_parent_sid_id := v_sid_id;
	END LOOP;
	IF v_sid_id IS NULL THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with path '||in_path||' and parent '||in_parent_sid_id||' was not found');
	END IF;
	RETURN v_sid_id;
END GetSIDFromPath;

PROCEDURE GetHelperInfoFromClassID(
	in_object_class_id		IN Security_Pkg.T_SID_ID,
	out_helper_pkg			OUT SECURABLE_OBJECT_CLASS.helper_pkg%TYPE,
	out_helper_prog_id		OUT SECURABLE_OBJECT_CLASS.helper_prog_id%TYPE,
	out_parent_class_id		OUT Security_Pkg.T_CLASS_ID
) AS
	CURSOR cur_helper IS
		SELECT helper_pkg, helper_prog_id, parent_class_id
		  FROM SECURABLE_OBJECT_CLASS
		 WHERE class_id = in_object_class_id;
BEGIN
	OPEN cur_helper;
	FETCH cur_helper INTO out_helper_pkg, out_helper_prog_id, out_parent_class_id;
	IF cur_helper%NOTFOUND THEN
		out_helper_pkg :=NULL;
		out_helper_prog_id:=NULL;
		out_parent_class_id:=NULL;
	END IF;
	
END GetHelperInfoFromClassID;

PROCEDURE GetHelperInfoFromSID(
	in_sid_id				IN Security_Pkg.T_SID_ID,
	out_helper_pkg			OUT SECURABLE_OBJECT_CLASS.helper_pkg%TYPE,
	out_helper_prog_id		OUT SECURABLE_OBJECT_CLASS.helper_prog_id%TYPE
) AS
	CURSOR cur_helper IS
		SELECT helper_pkg, helper_prog_id
		  FROM SECURABLE_OBJECT_CLASS soc, SECURABLE_OBJECT so
		 WHERE soc.class_id = so.class_id AND so.sid_id = in_sid_id;
BEGIN
	OPEN cur_helper;
	FETCH cur_helper INTO out_helper_pkg, out_helper_prog_id;
	IF cur_helper%NOTFOUND THEN
		out_helper_pkg :=NULL;
		out_helper_prog_id:=NULL;
	END IF;
END GetHelperInfoFromSID;

PROCEDURE CreateSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_parent_sid		IN Security_Pkg.T_SID_ID,
	in_object_class_id  IN Security_Pkg.T_CLASS_ID,
	in_object_name		IN Security_Pkg.T_SO_NAME,
	out_sid_id			OUT Security_Pkg.T_SID_ID
) AS
	v_duplicates NUMBER;
	v_new_object_sid_id Security_Pkg.T_SID_ID;
	v_owner_sid Security_Pkg.T_SID_ID;
	v_helper_pkg VARCHAR2(255);
	v_helper_prog_id VARCHAR2(255);
	v_parent_class_id	Security_Pkg.T_CLASS_ID;
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, Security_Pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have sufficient permissions on the parent object with sid '||in_parent_sid);
	END IF;

	IF in_object_name IS NOT NULL THEN
		-- Check for duplicates
		SELECT COUNT(*) INTO v_duplicates
		  FROM securable_object
		 WHERE parent_sid_id = in_parent_sid
		   AND LOWER(name) = LOWER(in_object_name);
		IF v_duplicates <> 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate object name '||in_object_name||' with parent sid '||in_parent_sid);
		END IF;
		-- The path separator is not valid in an object name (in theory it is possible, but it
		-- needs to be quotable, and we don't support that at present, so it's better to not
		-- let people create objects that they can't find)
		IF INSTR(in_object_name, '/') <> 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_INVALID_OBJECT_NAME, 'Invalid object name '||in_object_name);
		END IF;
	END IF;

	-- Get object owner sid
	User_Pkg.GetSID(in_act_id, v_owner_sid);

	-- Insert a new object
	SELECT sid_id_seq.NEXTVAL INTO v_new_object_sid_id
	  FROM dual;
	INSERT INTO securable_object (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner)
	VALUES (v_new_object_sid_id, in_parent_sid, NULL, in_object_class_id, in_object_name,
			Security_Pkg.SOFLAG_INHERIT_DACL, v_owner_sid);

	-- inherit ACEs from parent (...)
	IF in_parent_sid IS NOT NULL THEN
		Acl_Pkg.PASSACEStochild(in_parent_sid, v_new_object_sid_id);
	END IF;
	
	-- call helper pkg if one exists
	GetHelperInfoFromClassID(in_object_class_id, v_helper_pkg, v_helper_prog_id, v_parent_class_id);

	-- if inherited from group then...
	-- RK - removed this - not sure why it's required?
	-- if you want to create a broup you call createGroup
	-- which does this for you? Probably before I added
	-- CreateGroupWithClass?
	/*
	IF v_parent_class_id = Security_Pkg.SO_GROUP THEN
		INSERT INTO GROUP_TABLE (SID_ID, GROUP_TYPE)
		VALUES (v_new_object_sid_id, Security_Pkg.GROUP_TYPE_DISTRIBUTION);
	END IF;
	*/
	
	IF v_helper_pkg IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.CreateObject(:1,:2,:3,:4,:5);end;'
			USING in_act_id,v_new_object_sid_id,in_object_class_id,in_object_name,in_parent_sid;
	END IF;
	out_sid_id := v_new_object_sid_id;

END;

PROCEDURE DeleteSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) AS
	CURSOR c_child IS
	   SELECT sid_id FROM SECURABLE_OBJECT WHERE parent_sid_id = in_sid_id;
	v_dacl_id Security_Pkg.T_ACL_ID;
	v_class_id Security_Pkg.T_CLASS_ID;
	v_helper_pkg VARCHAR2(255);
	v_helper_prog_id VARCHAR2(255);
BEGIN
	-- first check delete permission
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.permission_delete) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have delete permission on the object with sid '||in_sid_id||', or one of its child objects');
	END IF;

	FOR r_child IN c_child LOOP
	   DeleteSO(in_act_id, r_child.sid_id);
	END LOOP;

	-- we do this first so that the helper code can clear up
	-- and still check permissions etc
	-- call helper pkg if one exists
	GetHelperInfoFromSID(in_sid_id, v_helper_pkg, v_helper_prog_id);
	IF v_helper_pkg IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.DeleteObject(:1,:2);end;'
			USING in_act_id,in_sid_id;
	END IF;

	-- delete DACL, if one exists
	v_dacl_id := Acl_Pkg.GetDACLIDForSID(in_sid_id);
	IF NOT v_dacl_id IS NULL THEN
		DELETE acl
		 WHERE acl_id = v_dacl_id;
	END IF;

	DELETE acl
	 WHERE sid_id = in_sid_id;

	-- this securable object may be a user, or a group.  If so delete the necessary records
	DELETE user_password_history
	 WHERE sid_id = in_sid_id;

	DELETE user_certificates
	 WHERE sid_id = in_sid_id;

	DELETE user_table
	 WHERE sid_id = in_sid_id;
	 
	DELETE group_members
	 WHERE member_sid_id = in_sid_id
		OR group_sid_id = in_sid_id;

	DELETE group_table
	 WHERE sid_id = in_sid_id;
	  
	-- references user/group and application
	DELETE home_page
	 WHERE sid_id = in_sid_id OR app_sid = in_sid_id;

	DELETE web_resource
	 WHERE sid_id = in_sid_id;

	UPDATE securable_object
	   SET application_sid_id = NULL
	 WHERE sid_id = in_sid_id;

	DELETE website
	 WHERE web_root_sid_id = in_sid_id OR application_sid_id = in_sid_id;
	 
	DELETE menu
	 WHERE sid_id = in_sid_id;
	 
	DELETE acc_policy_pwd_regexp
	 WHERE account_policy_sid = in_sid_id;

	DELETE account_policy
	 WHERE sid_id = in_sid_id;

	DELETE securable_object_attributes
	 WHERE sid_id = in_sid_id;
	 
	-- delete any keyed ACLs
	DELETE acl WHERE acl_id IN (
		SELECT acl_id 
		  FROM securable_object_keyed_acl
		 WHERE sid_id = in_sid_id);
		 
	DELETE securable_object_keyed_acl
	 WHERE sid_id = in_sid_id;

	-- we need this in case we're deleting the app itself
	UPDATE securable_object
	   SET application_sid_id = null
	 WHERE application_sid_id = in_sid_id;

	DELETE application
	 WHERE application_sid_id = in_sid_id;

	-- finally delete securable object itself
	DELETE securable_object
	 WHERE sid_id = in_sid_id;
END DeleteSO;

PROCEDURE MoveSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_parent_sid	IN Security_Pkg.T_SID_ID
)
AS
BEGIN
	MoveSO(in_act_id, in_sid_id, in_new_parent_sid, 0);
END;

PROCEDURE MoveSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_parent_sid	IN Security_Pkg.T_SID_ID,
	in_overwrite		IN NUMBER
)
AS
	v_count NUMBER;
	v_object_name security_pkg.T_SO_NAME;
	v_helper_pkg VARCHAR2(255);
	v_helper_prog_id VARCHAR2(255);
	v_duplicates NUMBER;
BEGIN
	--First of all is it logical to do this move.  Will be
	--making the parent one of the descendants?  If so this
	--will make a closed loop which isn't allowed
	SELECT COUNT(*) INTO v_count
	  FROM (SELECT sid_id FROM SECURABLE_OBJECT START WITH sid_id = in_sid_id CONNECT BY PRIOR sid_id = parent_sid_id)
	  WHERE sid_id = in_new_parent_sid;
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_MOVED_UNDER_SELF, 'Can''t move the object with sid '||in_sid_id||' under itself');
	END IF;
	

	--Now check permissions on both the object we are trying to move, and
	--the new proposed parent
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
									'You do not have permission to move the object with sid '||in_sid_id);
	END IF;
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_new_parent_sid, Security_Pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have permission to move the object with sid '||
									in_sid_id||' to be a child of the object with sid '||in_new_parent_sid);
	END IF;

	-- Now check for dupe object name (if object name is not null - you can have
	-- multiple objects with a null name)
	SELECT LOWER(name) 
	  INTO v_object_name
	  FROM securable_object
	 WHERE sid_id = in_sid_id;
	
	IF v_object_name IS NOT NULL THEN
		SELECT COUNT(*) INTO v_duplicates
		  FROM SECURABLE_OBJECT
		 WHERE parent_sid_id = in_new_parent_sid
		   AND LOWER(NAME) = v_object_name;

		IF v_duplicates = 1 AND in_overwrite = 1 THEN
			SELECT sid_id INTO v_duplicates
			  FROM securable_object
			 WHERE parent_sid_id = in_new_parent_sid
			   AND LOWER(NAME) = v_object_name;
			   
			DeleteSO(in_act_id, v_duplicates);			   
		ELSIF v_duplicates <> 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 
				'Duplicate object name moving the object with sid '||in_sid_id||' to be a child of '||in_new_parent_sid);
		END IF;
	END IF;
	
	--All seems well so move the object
	UPDATE SECURABLE_OBJECT
	   SET parent_sid_id = in_new_parent_sid
	 WHERE sid_id = in_sid_id;
	 
	-- propagate permisisons downwards from parent
	acl_pkg.PropogateACEs(in_act_id, in_new_parent_sid);

	-- call helper pkg if one exists
	GetHelperInfoFromSID(in_sid_id, v_helper_pkg, v_helper_prog_id);
	IF v_helper_pkg IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.MoveObject(:1,:2,:3);end;'
			USING in_act_id,in_sid_id, in_new_parent_sid;
	END IF;
END MoveSO;

PROCEDURE RenameSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_object_name		IN Security_Pkg.T_SO_NAME
)
AS
	v_duplicates NUMBER;
	v_helper_pkg VARCHAR2(255);
	v_helper_prog_id VARCHAR2(255);
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.permission_write) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have permission to rename the object with sid '||in_sid_id);
	END IF;
	IF in_object_name IS NOT NULL THEN
		SELECT COUNT(*) INTO v_duplicates
		  FROM SECURABLE_OBJECT
		 WHERE parent_sid_id = (SELECT parent_sid_id FROM SECURABLE_OBJECT WHERE sid_id = in_sid_id)
		   AND LOWER(NAME) = LOWER(in_object_name)
		   AND sid_id <> in_sid_id;
		IF v_duplicates <> 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 
				'Duplicate object name renaming the object with sid '||in_sid_id);
		END IF;
		-- Check for invalid characters
		IF INSTR(in_object_name, '/') <> 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_INVALID_OBJECT_NAME, 
				'Invalid object name renaming the object with sid '||in_sid_id);
		END IF;
	END IF;


	UPDATE SECURABLE_OBJECT
	   SET NAME = in_object_name
	 WHERE sid_id = in_sid_id;

	-- call helper pkg if one exists
	GetHelperInfoFromSID(in_sid_id, v_helper_pkg, v_helper_prog_id);
	IF v_helper_pkg IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.RenameObject(:1,:2,:3);end;'
			USING in_act_id,in_sid_id, in_object_name;
	END IF;
END RenameSO;

PROCEDURE TakeOwnershipOwnerOK(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_new_owner_sid_id IN Security_Pkg.T_SID_ID
)
AS
BEGIN
	-- Check that you can take ownership
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have take ownership permission on the object with sid '||in_sid_id);
	END IF;

	-- Set the new owner
	UPDATE SECURABLE_OBJECT
	   SET owner = in_new_owner_sid_id
	 WHERE sid_id = in_sid_id;

	-- This is a bit unnecessary, should be covered by IsAccessAllowedSID
	IF SQL%ROWCOUNT=0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 
			'You cannot take ownership of the object with sid '||in_sid_id||' because it does not exist');
	END IF;
END TakeOwnershipOwnerOK;

PROCEDURE TakeOwnership(
	in_act_id IN Security_Pkg.T_ACT_ID,
	in_sid_id IN Security_Pkg.T_SID_ID,
	in_new_owner_sid_id IN Security_Pkg.T_SID_ID
)
AS
BEGIN
	-- Check that you are taking ownership with something in your ACT
	IF NOT Act_Pkg.IsUserOrGroupInACT(in_act_id, in_new_owner_sid_id) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_INVALID_OWNER, 
			'The new owner of the object with sid '||in_sid_id||' must be you');
	END IF;

	TakeOwnershipOwnerOK(in_act_id,in_sid_id,in_new_owner_sid_id);
END TakeOwnership;

PROCEDURE TakeOwnershipRecursiveOwnerOK(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_sid_id				IN Security_Pkg.T_SID_ID,
	in_new_owner_sid_id		IN Security_Pkg.T_SID_ID
)
AS
	CURSOR c_child IS
	   SELECT sid_id
		 FROM SECURABLE_OBJECT
		WHERE parent_sid_id = in_sid_id;
BEGIN
	-- grab it
	TakeOwnershipOwnerOK(in_act_id,in_sid_id,in_new_owner_sid_id);
	-- repeat for each child
	FOR r_child IN c_child LOOP
		TakeOwnershipOwnerOK(in_act_id, r_child.sid_id, in_new_owner_sid_id);
		-- and for their children
		TakeOwnershipRecursiveOwnerOK(in_act_id, r_child.sid_id, in_new_owner_sid_id);
	END LOOP;
END TakeOwnershipRecursiveOwnerOK;

PROCEDURE TakeOwnershipRecursive(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_sid_id				IN Security_Pkg.T_SID_ID,
	in_new_owner_sid_id		IN Security_Pkg.T_SID_ID
)
AS
BEGIN
	-- Check that you are taking ownership with something in your ACT
	IF NOT Act_Pkg.IsUserOrGroupInACT(in_act_id, in_new_owner_sid_id) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_INVALID_OWNER, 
			'The new owner of the object with sid '||in_sid_id||' must be you');
	END IF;
	TakeOwnershipRecursiveOwnerOK(in_act_id,in_sid_id,in_new_owner_sid_id);
END TakeOwnershipRecursive;

PROCEDURE SetFlags(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_flags			IN Security_Pkg.T_SO_FLAGS
) AS
BEGIN
	UPDATE SECURABLE_OBJECT
	   SET flags = in_flags
	 WHERE sid_id = in_sid_id;
END SetFlags;

PROCEDURE SetFlag(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_flag				IN Security_Pkg.T_SO_FLAGS
) AS
BEGIN
	UPDATE SECURABLE_OBJECT
	   SET flags = Bitwise_Pkg.bitor(flags,in_flag)
	 WHERE sid_id = in_sid_id;
END;

PROCEDURE ClearFlag(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_flag				IN Security_Pkg.T_SO_FLAGS
) AS
BEGIN
	UPDATE SECURABLE_OBJECT
	   SET flags = bitand(flags,Bitwise_Pkg.bitnot(in_flag))
	 WHERE sid_id = in_sid_id;
END;


FUNCTION GetParent(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN Security_Pkg.T_SID_ID
AS
	v_parent_sid_id		Security_Pkg.T_SID_ID;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	SELECT parent_sid_id 
	  INTO v_parent_sid_id 
	  FROM securable_object
	 WHERE sid_id = in_sid_id;
	RETURN v_parent_sid_id;
END;


PROCEDURE GetParents(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
) AS
BEGIN
	OPEN out_cursor FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, NAME, flags, owner, description
		  FROM TABLE ( Securableobject_Pkg.GetParentsAsTable(in_act_id, in_sid_id) );
END;

FUNCTION GetParentsAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_TABLE
AS
	v_parsed_sid_id Security_Pkg.T_SID_ID;
	v_table 		T_SO_TABLE;
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied listing contents on the object with sid '||in_sid_id);
	END IF;
	SELECT NVL(link_sid_id, in_sid_id)
	  INTO v_parsed_sid_id 
	  FROM securable_object 
	 WHERE sid_id = in_sid_id;

	SELECT CAST(MULTISET(
		SELECT /*+ALL_ROWS*/ so.sid_id, parent_sid_id, dacl_id, class_id, NAME, flags, owner, sod.description
		  FROM securable_object so
	 LEFT JOIN securable_object_description sod ON so.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	   CONNECT BY PRIOR parent_sid_id=so.sid_id
		 START WITH so.sid_id=in_sid_id) AS T_SO_TABLE) INTO v_table 
	  FROM dual;
	RETURN v_table;
END;

PROCEDURE GetSO(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
) AS
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read permissions on the object with sid '||in_sid_id);
	END IF;

	OPEN out_cursor FOR
		SELECT so.SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, SOD.DESCRIPTION
		  FROM securable_object so
	 LEFT JOIN securable_object_description sod ON so.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE so.SID_ID = in_sid_id;
END;

FUNCTION GetSOAsRowObject(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_ROW
AS
	CURSOR c IS
		SELECT so.SID_ID, PARENT_SID_ID, DACL_ID, CLASS_ID, NAME, FLAGS, OWNER, sod.DESCRIPTION
		  FROM securable_object so
	 LEFT JOIN securable_object_description sod ON so.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE so.SID_ID = in_sid_id;
	r		c%ROWTYPE;
	v_row	T_SO_ROW;
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read permissions on the object with sid '||in_sid_id);
	END IF;
	
	OPEN c;
	FETCH c INTO r;
	
	v_row  := T_SO_ROW(r.sid_Id, r.parent_sid_id, r.dacl_id, r.class_id, r.name, r.flags, r.owner, r.description);
	
	RETURN v_row;
END;

PROCEDURE GetChildren(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
) AS
BEGIN
	OPEN out_cursor FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, NAME, flags, owner, description
		  FROM TABLE ( Securableobject_Pkg.GetChildrenAsTable(in_act_id, in_sid_id) );
END;

FUNCTION GetChildrenAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_TABLE
AS
	v_parsed_sid_id Security_Pkg.T_SID_ID;
	v_table 		T_SO_TABLE;
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied listing contents on the object with sid '||in_sid_id);
	END IF;
	SELECT NVL(link_sid_id, sid_id)
	  INTO v_parsed_sid_id
	  FROM securable_object
	 WHERE sid_id = in_sid_id;

	SELECT CAST(MULTISET(
		SELECT so.sid_id, parent_sid_id, dacl_id, class_id, h.NAME, flags, owner, h.description
		  FROM securable_object so, 
			   (SELECT NVL(link_sid_id, sobj.sid_id) sid_id, name, sod.description
				  FROM securable_object sobj
			 LEFT JOIN securable_object_description sod on sobj.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
				 WHERE parent_sid_id = in_sid_id) h
		 WHERE so.SID_ID = h.SID_ID) AS T_SO_TABLE) INTO v_table FROM dual;
	RETURN v_table;
END;

FUNCTION GetSIDsWithPermAsTable(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sids				IN	security.T_SID_TABLE,
	in_permission_set	IN 	security_pkg.T_PERMISSION
) 
RETURN T_SO_TABLE
AS
	CURSOR c_acl IS
	   SELECT /*+ALL_ROWS CARDINALITY(sids 1000)*/ acl.ACE_TYPE, bitand(acl.permission_set, in_permission_set) permission_set, 
			  so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id, so.name, so.flags, so.owner, sod.description
		 FROM act, acl, securable_object so, TABLE(in_sids) sids, securable_object_description sod 
		WHERE acl.ACL_ID = so.dacl_id AND
			  act.ACT_ID = in_act_id AND
			  act.ACT_TYPE IN (security_pkg.ACT_TYPE_USER,security_pkg.ACT_TYPE_GROUP) AND
			  act.SID_ID = acl.SID_ID AND
			  bitand(acl.permission_set, in_permission_set) != 0 AND
			  so.sid_id = sids.column_value AND
			  so.sid_id = sod.sid_id(+) AND 
			  NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en') = sod.lang
	 ORDER BY so.sid_id, ACL_INDEX ASC, ACT_INDEX ASC;
	r_acl 			c_acl%ROWTYPE;
	v_granted 		BINARY_INTEGER;
	v_last_sid_id 	security_pkg.T_SID_ID;
	v_table			T_SO_TABLE := T_SO_TABLE();
BEGIN
	-- Check that the access token is valid
	security_pkg.CheckACT(in_act_id);
	
	IF security_pkg.IsAdmin(in_act_id) THEN
		SELECT T_SO_ROW(so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id, so.name, so.flags, so.owner, sod.description)
			   BULK COLLECT INTO v_table
		  FROM securable_object so, TABLE(in_sids) sids, securable_object_description sod
		 WHERE so.sid_id = sids.column_value
		   AND so.sid_id = sod.sid_id(+)
		   AND NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en') = sod.lang;
		RETURN v_table;
	END IF;
   
	-- Now use this token to access values
	OPEN c_acl;
	FETCH c_acl INTO r_acl;

	WHILE c_acl%FOUND LOOP
		v_last_sid_id := r_acl.sid_id;
		v_granted := 0;

		WHILE v_last_sid_id = r_acl.sid_id LOOP 
			-- deny ace => denied
			IF r_acl.ace_type = security_pkg.ACE_TYPE_DENY THEN
				EXIT;
			END IF;
			-- add permissions in
			v_granted := bitwise_pkg.bitor(v_granted, r_acl.permission_set);
			-- if sufficient permissions, return allowed
			IF v_granted = in_permission_set THEN
				v_table.extend;
				v_table ( v_table.count ) := T_SO_ROW (r_acl.sid_id, r_acl.parent_sid_id, r_acl.dacl_id,
						 r_acl.class_id, r_acl.name, r_acl.flags, r_acl.owner, r_acl.description);
				EXIT;
			END IF;

			FETCH c_acl INTO r_acl;
			EXIT WHEN c_acl%NOTFOUND;
		END LOOP;

		WHILE v_last_sid_id = r_acl.sid_id LOOP
			FETCH c_acl INTO r_acl;
			EXIT WHEN c_acl%NOTFOUND;
		END LOOP;
	END LOOP;
	CLOSE c_acl;
	RETURN v_table;
END;

PROCEDURE GetSIDsWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sids				IN	security.T_SID_TABLE,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, description
		  FROM TABLE ( Securableobject_Pkg.GetSIDsWithPermAsTable(in_act_id, in_sids, in_permission_set) );
END;

PROCEDURE GetSIDsWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sids				IN	security_pkg.T_SID_IDS,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_sid_ids			security.T_SID_TABLE;
BEGIN
	-- N.B. must be two separate lines, combining them gives ORA-00904: security_pkg.sidarraytotable: invalid identifier
	v_sid_ids := security_pkg.SidArrayToTable(in_sids);
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, description
		  FROM TABLE ( Securableobject_Pkg.GetSIDsWithPermAsTable(in_act_id, v_sid_ids, in_permission_set) );
END;

FUNCTION GetChildrenWithPermAsTable(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION
) 
RETURN T_SO_TABLE
AS
	CURSOR c_acl IS
	   SELECT acl.ACE_TYPE, bitand(acl.permission_set, in_permission_set) permission_set, 
			  so.sid_id, in_sid_id parent_sid_id, so.dacl_id, so.class_id, so.name, so.flags, so.owner, sod.description
		 FROM act, acl, securable_object so
	LEFT JOIN securable_object_description sod ON so.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		WHERE acl.ACL_ID = so.dacl_id AND
			  act.ACT_ID = in_act_id AND
			  act.ACT_TYPE IN (security_pkg.ACT_TYPE_USER,security_pkg.ACT_TYPE_GROUP) AND
			  act.SID_ID = acl.SID_ID AND
			  bitand(acl.permission_set, in_permission_set) != 0 AND
			  so.parent_sid_id = in_sid_id
	 ORDER BY so.sid_id, ACL_INDEX ASC, ACT_INDEX ASC;
	r_acl 			c_acl%ROWTYPE;
	v_granted 		BINARY_INTEGER;
	v_last_sid_id 	security_pkg.T_SID_ID;
	v_table			T_SO_TABLE := T_SO_TABLE();
BEGIN
	-- Check that the access token is valid
	security_pkg.CheckACT(in_act_id);
	
	IF security_pkg.IsAdmin(in_act_id) THEN
		SELECT T_SO_ROW(so.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, description)
			   BULK COLLECT INTO v_table
		  FROM securable_object so
	 LEFT JOIN SECURABLE_OBJECT_DESCRIPTION sod ON so.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE parent_sid_id = in_sid_id;
		RETURN v_table;
	END IF;
   
	-- Now use this token to access values
	OPEN c_acl;
	FETCH c_acl INTO r_acl;

	WHILE c_acl%FOUND LOOP
		v_last_sid_id := r_acl.sid_id;
		v_granted := 0;

		WHILE v_last_sid_id = r_acl.sid_id LOOP 
			-- deny ace => denied
			IF r_acl.ace_type = security_pkg.ACE_TYPE_DENY THEN
				EXIT;
			END IF;
			-- add permissions in
			v_granted := bitwise_pkg.bitor(v_granted, r_acl.permission_set);
			-- if sufficient permissions, return allowed
			IF v_granted = in_permission_set THEN
				v_table.extend;
				v_table ( v_table.count ) := T_SO_ROW (r_acl.sid_id, r_acl.parent_sid_id, r_acl.dacl_id,
						 r_acl.class_id, r_acl.name, r_acl.flags, r_acl.owner, r_acl.description);
				EXIT;
			END IF;

			FETCH c_acl INTO r_acl;
			EXIT WHEN c_acl%NOTFOUND;
		END LOOP;

		WHILE v_last_sid_id = r_acl.sid_id LOOP
			FETCH c_acl INTO r_acl;
			EXIT WHEN c_acl%NOTFOUND;
		END LOOP;
	END LOOP;
	CLOSE c_acl;
	RETURN v_table;
END GetChildrenWithPermAsTable;


PROCEDURE GetChildrenWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, description
		  FROM TABLE ( Securableobject_Pkg.GetChildrenWithPermAsTable(in_act_id, in_sid_id, in_permission_set) );
END GetChildrenWithPerm;


PROCEDURE GetDescendants(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	OPEN out_cursor FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level
		  FROM TABLE ( Securableobject_Pkg.GetDescendantsAsTable(in_act_id, in_sid_id) );
END GetDescendants;


FUNCTION GetDescendantsAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN T_SO_DESCENDANTS_TABLE
AS
	v_parsed_sid_id Security_Pkg.T_SID_ID;
	v_table 		T_SO_DESCENDANTS_TABLE;
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied listing contents on the object with sid '||in_sid_id);
	END IF;
	SELECT NVL(link_sid_id, sid_id)
	  INTO v_parsed_sid_id
	  FROM securable_object
	 WHERE sid_id = in_sid_id;
	
	SELECT CAST(MULTISET(
		SELECT s.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level, is_leaf, sod.description
		  FROM (
			SELECT /*+ALL_ROWS*/ so.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, level so_level, CONNECT_BY_ISLEAF is_leaf
			  FROM securable_object so
		START WITH parent_sid_id = in_sid_id
		CONNECT BY PRIOR NVL(link_sid_id, so.sid_id) = parent_sid_id) s
		LEFT JOIN securable_object_description sod on s.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en'))
	AS T_SO_DESCENDANTS_TABLE) INTO v_table FROM dual;
	RETURN v_table;
END GetDescendantsAsTable;


FUNCTION GetDescendantsWithPermAsTable(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION
)
RETURN T_SO_DESCENDANTS_TABLE
IS
	CURSOR c_acl IS
	   SELECT /*+ALL_ROWS*/
			  acl.ACE_TYPE, bitand(acl.permission_set, in_permission_set) permission_set, 
			  so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id, so.name, so.flags, so.owner, 
			  so.so_level so_level, so.is_leaf, so.description
		 FROM act, acl, (
				SELECT s.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level, rown, is_leaf, sod.description
				  FROM (
					SELECT sobj.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, level so_level, rownum rown, CONNECT_BY_ISLEAF is_leaf
					  FROM securable_object sobj
				START WITH parent_sid_id = in_sid_id
				CONNECT BY PRIOR NVL(link_sid_id, sobj.sid_id) = parent_sid_id
				) s
			 LEFT JOIN securable_object_description sod ON sod.sid_id = s.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			
			) so
		WHERE acl.ACL_ID = so.dacl_id AND
			  act.ACT_ID = in_act_id AND
			  act.ACT_TYPE IN (security_pkg.ACT_TYPE_USER,security_pkg.ACT_TYPE_GROUP) AND
			  act.SID_ID = acl.SID_ID AND
			  bitand(acl.permission_set, in_permission_set) != 0
	 ORDER BY so.rown, ACL_INDEX ASC, ACT_INDEX ASC;
	r_acl					c_acl%ROWTYPE;
	v_granted 				BINARY_INTEGER;
	v_last_sid_id 			security_pkg.T_SID_ID;
	v_last_parent_sid_id	security_pkg.T_SID_ID;
	v_last_level			BINARY_INTEGER;
	v_table 				T_SO_DESCENDANTS_TABLE := T_SO_DESCENDANTS_TABLE();
	TYPE t_parents IS TABLE OF security_pkg.T_SID_ID INDEX BY BINARY_INTEGER;
	v_parents				t_parents;
BEGIN
	-- Check that the access token is valid
	security_pkg.CheckACT(in_act_id);

	IF security_pkg.IsAdmin(in_act_id) THEN
		SELECT T_SO_DESCENDANTS_ROW(s.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, level, CONNECT_BY_ISLEAF, description)
			   BULK COLLECT INTO v_table
		  FROM (
			SELECT so.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, level, CONNECT_BY_ISLEAF
			  FROM securable_object so
			   START WITH parent_sid_id = in_sid_id
			   CONNECT BY PRIOR NVL(link_sid_id, so.sid_id) = parent_sid_id
			) s
	 LEFT JOIN securable_object_description sod ON sod.sid_id = s.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
		RETURN v_table;
	END IF;

	-- Now use this token to access values
	OPEN c_acl;
	FETCH c_acl INTO r_acl;
	IF c_acl%NOTFOUND THEN
		GOTO done;
	END IF;
	
	v_last_sid_id := in_sid_id;
	v_last_level := 0;
	
	LOOP
		-- skip over things that we have already granted access to, and fix broken trees
		WHILE v_last_sid_id = r_acl.sid_id OR NOT (
				(r_acl.so_level <= v_last_level AND r_acl.parent_sid_id = v_parents(r_acl.so_level)) OR
				(r_acl.so_level = v_last_level + 1 AND r_acl.parent_sid_id = v_last_sid_id)) LOOP
			FETCH c_acl INTO r_acl;
			IF c_acl%NOTFOUND THEN
				GOTO done;
			END IF;				
		END LOOP;

		v_last_level := r_acl.so_level;
		v_parents(v_last_level) := r_acl.parent_sid_id;
		v_last_sid_id := r_acl.sid_id;
		v_granted := 0;

		WHILE v_last_sid_id = r_acl.sid_id LOOP 
			-- deny ace => denied
			IF r_acl.ace_type = security_pkg.ACE_TYPE_DENY THEN
				EXIT;
			END IF;
			-- add permissions in
			v_granted := bitwise_pkg.bitor(v_granted, r_acl.permission_set);
			-- if sufficient permissions, return allowed
			IF v_granted = in_permission_set THEN
				v_table.extend;
				v_table( v_table.count ) := T_SO_DESCENDANTS_ROW
					(r_acl.sid_id, r_acl.parent_sid_id, r_acl.dacl_id,
					 r_acl.class_id, r_acl.name, r_acl.flags, 
					 r_acl.owner, r_acl.so_level, r_acl.is_leaf, r_acl.description);
				EXIT;
			END IF;

			FETCH c_acl INTO r_acl;
			IF c_acl%NOTFOUND THEN
				GOTO done;
			END IF;
		END LOOP;
	END LOOP;
	
	<<done>>
	CLOSE c_acl;
	RETURN v_table;
END;


PROCEDURE GetDescendantsWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level
		  FROM TABLE (  Securableobject_Pkg.GetDescendantsWithPermAsTable(in_act_id, in_sid_id, in_permission_set) );
END GetDescendantsWithPerm;


FUNCTION GetTreeWithPermAsTable(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	in_fetch_depth		IN	NUMBER DEFAULT NULL,
	in_limit			IN	NUMBER DEFAULT NULL,
	in_hide_root		IN	NUMBER DEFAULT 0
)
RETURN T_SO_TREE_TABLE
IS
	CURSOR c_acl IS
	   SELECT acl.ACE_TYPE, bitand(acl.permission_set, in_permission_set) permission_set, 
			  so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id, so.name, so.flags, so.owner,
			  so.so_level so_level, so.is_leaf, so.path, sod.description
		 FROM act, acl, (
				SELECT sobj.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, level so_level, rownum rown,
					   CONNECT_BY_ISLEAF is_leaf, SYS_CONNECT_BY_PATH(name,'/') path
				  FROM securable_object sobj
				 WHERE in_fetch_depth IS NULL OR level <= in_fetch_depth
			START WITH (in_hide_root = 0 AND sobj.sid_id = in_sid_id) OR (in_hide_root = 1 AND parent_sid_id = in_sid_id)
			CONNECT BY PRIOR NVL(link_sid_id, sobj.sid_id) = parent_sid_id
	 ORDER SIBLINGS BY LOWER(name)
			) so
	LEFT JOIN securable_object_description sod ON sod.sid_id = so.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		WHERE acl.ACL_ID = so.dacl_id AND
			  act.ACT_ID = in_act_id AND
			  act.ACT_TYPE IN (security_pkg.ACT_TYPE_USER,security_pkg.ACT_TYPE_GROUP) AND
			  act.SID_ID = acl.SID_ID AND
			  bitand(acl.permission_set, in_permission_set) != 0
	 ORDER BY so.rown, ACL_INDEX ASC, ACT_INDEX ASC;
	r_acl					c_acl%ROWTYPE;
	v_granted 				BINARY_INTEGER;
	v_last_sid_id 			security_pkg.T_SID_ID;
	v_last_level			BINARY_INTEGER;
	v_table 				T_SO_TREE_TABLE := T_SO_TREE_TABLE();
	TYPE t_parents IS TABLE OF security_pkg.T_SID_ID INDEX BY BINARY_INTEGER;
	v_parents				t_parents;
BEGIN
	-- Check that the access token is valid
	security_pkg.CheckACT(in_act_id);

	IF security_pkg.IsAdmin(in_act_id) THEN
		SELECT T_SO_TREE_ROW (so.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, 
							  level, CONNECT_BY_ISLEAF, SYS_CONNECT_BY_PATH(name, '/'), description)
			   BULK COLLECT INTO v_table
		  FROM securable_object so
	 LEFT JOIN securable_object_description sod ON sod.sid_id = so.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE in_fetch_depth IS NULL OR level <= in_fetch_depth
			   START WITH (in_hide_root = 0 AND so.sid_id = in_sid_id) OR (in_hide_root = 1 AND parent_sid_id = in_sid_id)
			   CONNECT BY PRIOR NVL(link_sid_id, so.sid_id) = parent_sid_id;
		RETURN v_table;
	END IF;

	-- Now use this token to access values
	OPEN c_acl;
	FETCH c_acl INTO r_acl;
	IF c_acl%NOTFOUND OR in_limit = 0 THEN
		GOTO done;
	END IF;
	
	-- If we aren't hiding the root, then we need the parent of the root
	-- to check that the rows we have got initially are not orphans
	-- from the tree chopping query
	IF in_hide_root = 0 THEN
		SELECT parent_sid_id
		  INTO v_last_sid_id
		  FROM securable_object
		 WHERE sid_id = in_sid_id;		 
	ELSE
		v_last_sid_id := in_sid_id;
	END IF;
	v_last_level := 0;
	
	LOOP
		-- skip over things that we have already granted access to, and fix broken trees
		WHILE v_last_sid_id = r_acl.sid_id OR NOT (
				(r_acl.so_level <= v_last_level AND r_acl.parent_sid_id = v_parents(r_acl.so_level)) OR
				(r_acl.so_level = v_last_level + 1 AND r_acl.parent_sid_id = v_last_sid_id)) LOOP
			FETCH c_acl INTO r_acl;
			IF c_acl%NOTFOUND THEN
				GOTO done;
			END IF;
		END LOOP;

		v_last_level := r_acl.so_level;
		v_parents(v_last_level) := r_acl.parent_sid_id;
		v_last_sid_id := r_acl.sid_id;
		v_granted := 0;

		WHILE v_last_sid_id = r_acl.sid_id LOOP 
			-- deny ace => denied
			IF r_acl.ace_type = security_pkg.ACE_TYPE_DENY THEN
				EXIT;
			END IF;
			-- add permissions in
			v_granted := bitwise_pkg.bitor(v_granted, r_acl.permission_set);
			-- if sufficient permissions, return allowed
			IF v_granted = in_permission_set THEN
				v_table.extend;
				v_table( v_table.count ) := T_SO_TREE_ROW
					(r_acl.sid_id, r_acl.parent_sid_id, r_acl.dacl_id,
					 r_acl.class_id, r_acl.name, r_acl.flags, 
					 r_acl.owner, r_acl.so_level, r_acl.is_leaf, r_acl.path, r_acl.description);
				IF v_table.count = in_limit THEN
					GOTO done;
				END IF;
				EXIT;
			END IF;

			FETCH c_acl INTO r_acl;
			IF c_acl%NOTFOUND THEN
				GOTO done;
			END IF;
		END LOOP;
	END LOOP;
	
	<<done>>
	CLOSE c_acl;
	RETURN v_table;
END;


PROCEDURE GetTreeWithPerm(
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_sid_id			IN 	security_pkg.T_SID_ID,
	in_permission_set	IN 	security_pkg.T_PERMISSION,
	in_fetch_depth		IN	NUMBER DEFAULT NULL,
	in_limit			IN	NUMBER DEFAULT NULL,
	in_hide_root		IN	NUMBER DEFAULT 0,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level, is_leaf
		  FROM TABLE ( Securableobject_Pkg.GetTreeWithPermAsTable(in_act_id, in_sid_id, 
						in_permission_set, in_fetch_depth, in_limit) );
END;


FUNCTION GetACLKeysWithPermAsTable(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_permission_set		IN 	security_pkg.T_PERMISSION
)
RETURN T_KEYED_ACL_TABLE
AS
	CURSOR c_acl IS
	   SELECT /*+ ORDERED INDEX (acl PK_ACL) */ acl.ACE_TYPE, bitand(acl.permission_set, in_permission_set) permission_set, 
			  soea.sid_id, soea.key_id
		 FROM securable_object_keyed_acl soea, act, acl
		WHERE acl.ACL_ID = soea.acl_id AND
			  act.ACT_ID = in_act_id AND
			  act.ACT_TYPE IN (security_pkg.ACT_TYPE_USER,security_pkg.ACT_TYPE_GROUP) AND
			  act.SID_ID = acl.SID_ID AND
			  bitand(acl.permission_set, in_permission_set) != 0 AND
			  soea.sid_id = in_object_sid_id
	 ORDER BY soea.key_id, ACL_INDEX ASC, ACT_INDEX ASC;
	r_acl 			c_acl%ROWTYPE;
	v_granted 		BINARY_INTEGER;
	v_last_key_id 	security_pkg.T_SID_ID;
	v_table			T_KEYED_ACL_TABLE := T_KEYED_ACL_TABLE();
BEGIN
	-- Check that the access token is valid
	security_pkg.CheckACT(in_act_id);
	
	IF security_pkg.IsAdmin(in_act_id) THEN
		SELECT T_KEYED_ACL_ROW(key_id)
			   BULK COLLECT INTO v_table
		  FROM securable_object_keyed_acl
		 WHERE sid_id = in_object_sid_id;
		RETURN v_table;
	END IF;
	
	-- Now use this token to access values
	OPEN c_acl;
	FETCH c_acl INTO r_acl;

	WHILE c_acl%FOUND LOOP
		v_last_key_id := r_acl.key_id;
		v_granted := 0;

		WHILE v_last_key_id = r_acl.key_id LOOP 
			-- deny ace => denied
			IF r_acl.ace_type = security_pkg.ACE_TYPE_DENY THEN
				EXIT;
			END IF;
			-- add permissions in
			v_granted := bitwise_pkg.bitor(v_granted, r_acl.permission_set);
			-- if sufficient permissions, return allowed
			IF v_granted = in_permission_set THEN
				v_table.extend;
				v_table ( v_table.count ) := T_KEYED_ACL_ROW (r_acl.key_id);
				EXIT;  
			END IF;

			FETCH c_acl INTO r_acl;
			EXIT WHEN c_acl%NOTFOUND;
		END LOOP;

		WHILE v_last_key_id = r_acl.key_id LOOP
			FETCH c_acl INTO r_acl;
			EXIT WHEN c_acl%NOTFOUND;
		END LOOP;
	END LOOP;
	CLOSE c_acl;
	RETURN v_table;
END;


PROCEDURE GetACLKeysWithPerm(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_permission_set		IN 	security_pkg.T_PERMISSION,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT key_id
		  FROM TABLE ( Securableobject_Pkg.GetACLKeysWithPermAsTable(in_act_id, in_object_sid_id, in_permission_set) );	
END;


PROCEDURE AddKeyedACL(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_key_id				IN	security_pkg.T_SID_ID,
	in_acl_id				IN	security_pkg.T_ACL_ID
)
AS
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_object_sid_id, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write permissions on the object with sid '||in_object_sid_id);
	END IF;

	INSERT INTO securable_object_keyed_acl (sid_id, key_id, acl_id)
	VALUES (in_object_sid_id, in_key_id, in_acl_id);
END;


PROCEDURE RemoveKeyedACL(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	in_key_id				IN	security_pkg.T_SID_ID
)
AS
	CURSOR c_key IS
		SELECT acl_id 
		  FROM securable_object_keyed_acl
		 WHERE sid_id = in_object_sid_id AND key_id = in_key_id FOR UPDATE;
	r_key	c_key%ROWTYPE;
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_object_sid_id, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write permissions on the object with sid '||in_object_sid_id);
	END IF;

	OPEN c_key;
	FETCH c_key INTO r_key;
	IF c_key%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 
			'The keyed acl with key ' ||in_key_id||' for object '||in_object_sid_id||' was not found');
	END IF;
	DELETE FROM acl WHERE acl_id = r_key.acl_id;
	DELETE FROM securable_object_keyed_acl WHERE CURRENT OF c_key;
	CLOSE c_key;
END;


PROCEDURE GetKeyedACLs(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_object_sid_id		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_object_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read permissions on the object with sid '||in_object_sid_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT soka.key_id, acl.acl_id, acl.acl_index, acl.ace_type, acl.ace_flags, acl.sid_id, acl.permission_set
		  FROM securable_object_keyed_acl soka, acl
		 WHERE soka.sid_id = in_object_sid_id AND acl.acl_id = soka.acl_id
	  ORDER BY soka.key_id, soka.acl_id;
END;


PROCEDURE ReadAttributes(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	out_cursor			OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	OPEN out_cursor FOR
		SELECT a.attribute_id, a.class_id, a.NAME attribute_name, a.flags attribute_flags, soa.string_value, soa.number_value, soa.date_value, soa.blob_value, soa.isobject, soa.clob_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa, ATTRIBUTES a
		 WHERE soa.sid_id = in_sid_id AND a.attribute_id = soa.attribute_id;
END ReadAttributes;


/** Return the name of a securable object from its sid.
 */
FUNCTION GetName(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID
) RETURN Security_Pkg.T_SO_NAME
AS
	v_name Security_Pkg.T_SO_NAME;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	SELECT NAME INTO v_name FROM SECURABLE_OBJECT WHERE sid_id = in_sid_id;
	RETURN v_name;
END;


-- Helper to get an attribute ID, no security checks (not public!)
FUNCTION GetAttributeId(
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_ATTRIBUTE_ID
AS
	CURSOR c_a IS
		SELECT attribute_id 
		  FROM attributes a, securable_object so
		 WHERE a.name = LOWER(in_attribute_name) AND so.class_id = a.class_id AND
			   so.sid_id = in_sid_id;
	v_attribute_id Security_Pkg.T_ATTRIBUTE_ID;
BEGIN
	OPEN c_a;
	FETCH c_a INTO v_attribute_id;
	IF c_a%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 
			'Attribute '||in_attribute_name||' for object with sid '||TO_CHAR(in_sid_id)||' was not found');
	END IF;
	RETURN v_attribute_id;
END;


PROCEDURE DeleteNamedAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
)
AS
BEGIN
	DeleteAttribute(in_act_id, in_sid_id, GetAttributeId(in_sid_id, in_attribute_name));
END;


PROCEDURE DeleteAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
)
AS
BEGIN

	-- Check that you are allowed to write attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_WRITE_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write attributes permission on the object with sid '||in_sid_id);
	END IF;
	DELETE FROM securable_object_attributes
	 WHERE sid_id = in_sid_id AND attribute_id = in_attribute_id;
END;


FUNCTION GetNamedStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_SO_ATTRIBUTE_STRING
AS
	CURSOR c_attribute IS
		SELECT soa.string_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa, SECURABLE_OBJECT so, ATTRIBUTES a
		 WHERE so.sid_id = in_sid_id AND soa.sid_id = in_sid_id AND soa.attribute_id = a.attribute_id AND 
			   a.NAME = in_attribute_name AND so.class_id = a.class_id;
	r_attribute c_attribute%ROWTYPE;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Read the attribute
	OPEN c_attribute;
	FETCH c_attribute INTO r_attribute;
	IF c_attribute%NOTFOUND THEN
		RETURN NULL;
	END IF;
	RETURN r_attribute.string_value;
END;


FUNCTION GetStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
) RETURN Security_Pkg.T_SO_ATTRIBUTE_STRING
AS
	CURSOR c_attribute IS
		SELECT soa.string_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa
		 WHERE soa.sid_id = in_sid_id AND soa.attribute_id = in_attribute_id;
	r_attribute c_attribute%ROWTYPE;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Read the attribute
	OPEN c_attribute;
	FETCH c_attribute INTO r_attribute;
	IF c_attribute%NOTFOUND THEN
		RETURN NULL;
	END IF;
	RETURN r_attribute.string_value;
END;


PROCEDURE SetNamedStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_STRING
)
AS
BEGIN
	SetStringAttribute(
		in_act_id, in_sid_id, GetAttributeId(in_sid_id, in_attribute_name), in_attribute_value);
END;


PROCEDURE SetStringAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_STRING
)
AS
BEGIN
	-- Check that you are allowed to write attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_WRITE_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Set the attribute
	BEGIN
		INSERT INTO securable_object_attributes
			(sid_id, attribute_id, string_value, isobject)
		VALUES
			(in_sid_id, in_attribute_id, in_attribute_value, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE securable_object_attributes
			   SET string_value = in_attribute_value, number_value = null, date_value = null, blob_value = null, clob_value = null, isobject = 0
			 WHERE attribute_id = in_attribute_id AND sid_id = in_sid_id;
	END;
END;


FUNCTION GetNamedDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_SO_ATTRIBUTE_DATE
AS
	CURSOR c_attribute IS
		SELECT soa.date_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa, SECURABLE_OBJECT so, ATTRIBUTES a
		 WHERE so.sid_id = in_sid_id AND soa.sid_id = in_sid_id AND soa.attribute_id = a.attribute_id AND 
			   a.NAME = in_attribute_name AND so.class_id = a.class_id;
	r_attribute c_attribute%ROWTYPE;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Read the attribute
	OPEN c_attribute;
	FETCH c_attribute INTO r_attribute;
	IF c_attribute%NOTFOUND THEN
		RETURN NULL;
	END IF;
	RETURN r_attribute.date_value;
END;


FUNCTION GetDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
) RETURN Security_Pkg.T_SO_ATTRIBUTE_DATE
AS
	CURSOR c_attribute IS
		SELECT soa.date_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa
		 WHERE soa.sid_id = in_sid_id AND soa.attribute_id = in_attribute_id;
	r_attribute c_attribute%ROWTYPE;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Read the attribute
	OPEN c_attribute;
	FETCH c_attribute INTO r_attribute;
	IF c_attribute%NOTFOUND THEN
		RETURN NULL;
	END IF;
	RETURN r_attribute.date_value;
END;


PROCEDURE SetNamedDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_DATE
)
AS
BEGIN
	SetDateAttribute(
		in_act_id, in_sid_id, GetAttributeId(in_sid_id, in_attribute_name), in_attribute_value);
END;


PROCEDURE SetDateAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_DATE
)
AS
BEGIN
	-- Check that you are allowed to write attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_WRITE_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Set the attribute
	BEGIN
		INSERT INTO securable_object_attributes
			(sid_id, attribute_id, date_value, isobject)
		VALUES
			(in_sid_id, in_attribute_id, in_attribute_value, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE securable_object_attributes
			   SET string_value = null, number_value = null, date_value = in_attribute_value, blob_value = null, clob_value = null, isobject = 0
			 WHERE attribute_id = in_attribute_id AND sid_id = in_sid_id;
	END;
END;


FUNCTION GetNamedNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME
) RETURN Security_Pkg.T_SO_ATTRIBUTE_NUMBER
AS
	CURSOR c_attribute IS
		SELECT soa.number_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa, SECURABLE_OBJECT so, ATTRIBUTES a
		 WHERE so.sid_id = in_sid_id AND soa.sid_id = in_sid_id AND soa.attribute_id = a.attribute_id AND 
			   a.NAME = in_attribute_name AND so.class_id = a.class_id;
	r_attribute c_attribute%ROWTYPE;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Read the attribute
	OPEN c_attribute;
	FETCH c_attribute INTO r_attribute;
	IF c_attribute%NOTFOUND THEN
		RETURN NULL;
	END IF;
	RETURN r_attribute.number_value;
END;


FUNCTION GetNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID
) RETURN Security_Pkg.T_SO_ATTRIBUTE_NUMBER
AS
	CURSOR c_attribute IS
		SELECT soa.number_value
		  FROM SECURABLE_OBJECT_ATTRIBUTES soa
		 WHERE soa.sid_id = in_sid_id AND soa.attribute_id = in_attribute_id;
	r_attribute c_attribute%ROWTYPE;
BEGIN
	-- Check that you are allowed to read attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Read the attribute
	OPEN c_attribute;
	FETCH c_attribute INTO r_attribute;
	IF c_attribute%NOTFOUND THEN
		RETURN NULL;
	END IF;
	RETURN r_attribute.number_value;
END;


PROCEDURE SetNamedNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_name	IN Security_Pkg.T_ATTRIBUTE_NAME,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_NUMBER
)
AS
BEGIN
	SetNumberAttribute(
		in_act_id, in_sid_id, GetAttributeId(in_sid_id, in_attribute_name), in_attribute_value);
END;


PROCEDURE SetNumberAttribute(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_sid_id			IN Security_Pkg.T_SID_ID,
	in_attribute_id		IN Security_Pkg.T_ATTRIBUTE_ID,
	in_attribute_value	IN Security_Pkg.T_SO_ATTRIBUTE_NUMBER
)
AS
BEGIN
	-- Check that you are allowed to write attributes
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_WRITE_ATTRIBUTES) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write attributes permission on the object with sid '||in_sid_id);
	END IF;
	-- Set the attribute
	BEGIN
		INSERT INTO securable_object_attributes
			(sid_id, attribute_id, number_value, isobject)
		VALUES
			(in_sid_id, in_attribute_id, in_attribute_value, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE securable_object_attributes
			   SET string_value = null, number_value = in_attribute_value, date_value = null, blob_value = null, clob_value = null, isobject = 0
			 WHERE attribute_id = in_attribute_id AND sid_id = in_sid_id;
	END;
END;


FUNCTION GetPathFromSID(
	in_act_id			IN	Security_Pkg.T_ACT_ID,
	in_sid_id 			IN	Security_Pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_name VARCHAR2(4000);
	CURSOR c_tree IS
			SELECT name 
			  FROM SECURABLE_OBJECT
		CONNECT BY PRIOR parent_sid_id=sid_id
		START WITH sid_id=in_sid_id;
BEGIN
	-- Special: the root, which does not appear in the securable_object_tree
	IF in_sid_id = 0 THEN
		RETURN '//';
	END IF;
	FOR r_tree IN c_tree LOOP
		-- Append the current level to the name-so-far
		IF v_name IS NULL THEN
			v_name := r_tree.name;
		ELSE
			v_name := r_tree.name || '/' || v_name;
		END IF;
	END LOOP;
	IF v_name IS NULL THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid_id||' was not found');
	END IF;
	v_name := '/' || v_name;
	RETURN v_name;
END;

PROCEDURE UpsertDescription(
	in_act_id			IN  security_Pkg.T_ACT_ID,
	in_sid_id			IN	securable_object_description.sid_id%TYPE,
	in_lang				IN	securable_object_description.lang%TYPE,
	in_description		IN	securable_object_description.description%TYPE
)
AS
BEGIN

	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have permission to alter the description on the object with sid '||in_sid_id);
	END IF;

	BEGIN
		INSERT INTO securable_object_description (sid_id, lang, description)
		VALUES (in_sid_id, in_lang, in_description);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE securable_object_description
			   SET description = in_description
			 WHERE sid_id = in_sid_id
			   AND lang = in_lang;
	END;

END;

END Securableobject_Pkg;
/

--@..\groups_body
CREATE OR REPLACE PACKAGE BODY SECURITY.Group_Pkg IS

PROCEDURE CreateGroup(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_parent_sid	IN Security_Pkg.T_SID_ID,
	in_group_type	IN Security_Pkg.T_GROUP_TYPE,
	in_group_name	IN Security_Pkg.T_SO_NAME,
	out_group_sid	OUT Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	CreateGroupWithClass(in_act_id,	in_parent_sid, in_group_type, in_group_name,
		Security_Pkg.SO_SECURITY_GROUP, out_group_sid);	
END;

PROCEDURE CreateGroupWithClass(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_parent_sid	IN Security_Pkg.T_SID_ID,
	in_group_type	IN Security_Pkg.T_GROUP_TYPE,
	in_group_name	IN Security_Pkg.T_SO_NAME,
	in_class_id		IN security_pkg.T_CLASS_ID,
	out_group_sid	OUT Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	Securableobject_Pkg.CreateSO(in_act_id, in_parent_sid, in_class_id, in_group_name, out_group_sid);
	-- add the group table entry
	INSERT INTO group_table (sid_id, group_type)
	VALUES (out_group_sid, in_group_type);
END;


PROCEDURE DeleteGroup(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	Securableobject_Pkg.DeleteSO(in_act_id, in_group_sid);
END;

PROCEDURE AddMember(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_member_sid	IN Security_Pkg.T_SID_ID,
	in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_ID, in_group_sid, Security_Pkg.permission_write) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write permissions on the group with sid '||in_group_sid);
	END IF;
	BEGIN
		INSERT INTO group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END; 

PROCEDURE DeleteMember(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_member_sid	IN Security_Pkg.T_SID_ID,
	in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 	
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_ID, in_group_sid, Security_Pkg.permission_write) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write permission on the group with sid '||in_group_sid);
	END IF;
	DELETE
	  FROM group_members 
	 WHERE member_sid_id = in_member_sid and group_sid_id = in_group_sid;
END;

PROCEDURE DeleteAllMembers(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_ID, in_group_sid, Security_Pkg.permission_write) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have write permission on the group with sid '||in_group_sid);
	END IF;
	DELETE 
	  FROM group_members
	 WHERE group_sid_id = in_group_sid;
END;

PROCEDURE ListMembers(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_group_sid	IN Security_Pkg.T_SID_ID,
	out_record		OUT Security_Pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_ID, in_group_sid, Security_Pkg.permission_read) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read permission on the group with sid '||in_group_sid);
	END IF;
	OPEN out_record FOR
		SELECT sid_id,
			   parent_sid_id,
			   dacl_id,
			   class_id,
			   name,
			   flags,
			   owner 
		  FROM group_members gm, securable_object so
		 WHERE member_sid_id = sid_id
		   AND group_sid_id = in_group_sid;
END;

FUNCTION GetMembersAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_group_sid		IN Security_Pkg.T_SID_ID)
RETURN T_SO_TABLE
AS
	v_parsed_sid_id Security_Pkg.T_SID_ID;
	v_table 		T_SO_TABLE;
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_ID, in_group_sid, Security_Pkg.permission_read) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read permission on the group with sid '||in_group_sid);
	END IF;
	SELECT NVL(link_sid_id, sid_id)
	  INTO v_parsed_sid_id
	  FROM securable_object
	 WHERE sid_id = in_group_sid;

	SELECT CAST(MULTISET(
		SELECT /*+ INDEX (so IX_SO_SID_DACL_OWNER) */so.sid_id, parent_sid_id, dacl_id, class_id, NAME, flags, owner
		  FROM securable_object so, group_table gt, (
				SELECT member_sid_id 
				  FROM group_members
					   START WITH group_sid_id = in_group_sid
					   CONNECT BY NOCYCLE PRIOR member_sid_id = group_sid_id) x
		 WHERE so.sid_id = x.member_sid_id
		   AND gt.sid_id(+) = so.sid_id
		   AND gt.sid_id is NULL -- exclude groups
		) AS T_SO_TABLE) 
	  INTO v_table 
	  FROM dual;
	RETURN v_table;
END;				   

FUNCTION GetDirectMembersAsTable(
	in_act_id			IN Security_Pkg.T_ACT_ID,
	in_group_sid		IN Security_Pkg.T_SID_ID)
RETURN T_SO_TABLE
AS
	v_parsed_sid_id Security_Pkg.T_SID_ID;
	v_table 		T_SO_TABLE;
BEGIN
	-- Check that the user has list contents permission on this object
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_ID, in_group_sid, Security_Pkg.permission_read) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'You do not have read permission on the group with sid '||in_group_sid);
	END IF;
	
	SELECT NVL(link_sid_id, sid_id)
	  INTO v_parsed_sid_id
	  FROM securable_object
	 WHERE sid_id = in_group_sid;

	SELECT CAST(MULTISET(
			SELECT so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id, so.NAME, so.flags, so.owner
			  FROM securable_object so, group_members gm
			 WHERE gm.group_sid_id = in_group_sid
			   AND so.sid_id = gm.member_sid_id
		) AS T_SO_TABLE) 
	  INTO v_table 
	  FROM dual;
	  
	RETURN v_table;
END;				   


PROCEDURE GetGroupsOfWhichSOIsMember(
	in_act_id		IN Security_Pkg.T_ACT_ID,		
	in_sid_id 		IN Security_Pkg.T_SID_ID,
	out_cur			OUT Security_Pkg.T_OUTPUT_CUR
) AS
BEGIN					
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied reading the object with sid '||in_sid_id);
	END IF;
	-- returns all groups sid is member of, (but recursively, i.e. groups that that group is a member of etc)
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner
		  FROM securable_object 
		 WHERE sid_id IN (
				SELECT group_sid_id FROM group_members
					   START WITH member_sid_id = in_sid_id 
					   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id);
END;

FUNCTION GetGroupsForMemberAsTable (
	in_act_id		IN Security_Pkg.T_ACT_ID,		
	in_sid_id 		IN Security_Pkg.T_SID_ID
) RETURN T_SO_TABLE
AS
	v_table 		T_SO_TABLE;
BEGIN					
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied reading the object with sid '||in_sid_id);
	END IF;
	-- returns all groups sid is member of, (but recursively, i.e. groups that that group is a member of etc)
	SELECT CAST(MULTISET(
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner
		  FROM securable_object 
		 WHERE sid_id IN (
				SELECT group_sid_id FROM group_members
					   START WITH member_sid_id = in_sid_id 
			   CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id)
	  ) AS T_SO_TABLE) INTO v_table 
	  FROM dual;
	
	RETURN v_table;		
END;


PROCEDURE GetGroupsWhereSOIsDirectMember(
	in_act_id		IN Security_Pkg.T_ACT_ID,		
	in_sid_id 		IN Security_Pkg.T_SID_ID,
	out_cur			OUT Security_Pkg.T_OUTPUT_CUR
) AS
BEGIN					
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied reading the object with sid '||in_sid_id);
	END IF;
	-- returns all groups sid is member of, (but recursively, i.e. groups that that group is a member of etc)
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner
		  FROM securable_object 
		 WHERE sid_id IN (SELECT group_sid_id 
							FROM group_members 
						   WHERE member_sid_id = in_sid_id);
END;

FUNCTION GetGroupsDirectMemberAsTable(
	in_act_id		IN Security_Pkg.T_ACT_ID,		
	in_sid_id 		IN Security_Pkg.T_SID_ID
) RETURN T_SO_TABLE
AS
	v_table 		T_SO_TABLE;
BEGIN					
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, in_sid_id, Security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
			'Permission denied reading the object with sid '||in_sid_id);
	END IF;
	
	-- returns all groups sid is a direct member of
	SELECT CAST(MULTISET(
		SELECT so.sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, sod.description
		  FROM securable_object so
	 LEFT JOIN securable_object_description sod on so.sid_id = sod.sid_id AND sod.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 WHERE so.sid_id IN (SELECT group_sid_id 
							FROM group_members 
						   WHERE member_sid_id = in_sid_id)
	  ) AS T_SO_TABLE) INTO v_table 
	  FROM dual;
	
	RETURN v_table;	
END;

END Group_Pkg;
/

UPDATE security.version
   SET db_version = 53;

@update_tail
