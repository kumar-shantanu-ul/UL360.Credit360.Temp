/**
 * 
 * 
 * @param node		.
 */
CREATE OR REPLACE PACKAGE CSR.Tree_Pkg IS
/**
 * Starting at a specified point, this function works its way
 * up the tree, listing the children of each parent up to
 * specified point. It is used for finding the selected
 * node in a large tree, and only opening portions of the tree
 * required to reach this node
 *
 * @param in_act_id		Access token.
 * @param in_start_sid 	The sid of the node to start at.
 * @param in_top_sid 	The top-most point to read to.
 *
 * The output rowset is of the form:
 * sid_id, parent_sid_id, name, class_name, attribute_list, lvl
 *
 * Where attribute_list is an XML style list of attributes (name="value" ...)
 */
PROCEDURE GetRouteUpTree(
    in_act_id       IN  security_pkg.T_ACT_ID,
    in_start_sid 	IN  security_pkg.T_SID_ID,
    in_top_sid 		IN  security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * NOT FOR PUBLIC USE.
 * This is only here because I haven't found a way around fskcing restrict_references problem yet.
 */
/**
 * GetAttributeList
 * 
 * @param in_sid_id			The sid of the object
 * @param in_class_name		.
 * @return 					.
 */
FUNCTION GetAttributeList(
    in_sid_id		IN security_pkg.T_SID_ID,
	in_class_name	IN security_pkg.T_SO_NAME
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(GetAttributeList, WNDS, WNPS);

/**
 * Return a rowset suitable for constructing a treeview.
 * This has the fucked up semantics that you can't see objects
 * that you don't have read permissions on.
 *
 * @param in_act	Access token.
 * @param in_sid_id The sid of the root.
 * @param in_depth The depth to read to.
 *
 * The output rowset is of the form:
 * sid_id, name, attribute_list, level
 *
 * Where attribute_list is an XML style list of attributes (name="value" ...)
 */
PROCEDURE GetTree(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_sid_id 		IN  security_pkg.T_SID_ID,
	in_depth 		IN  NUMBER,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Return a rowset suitable for constructing a menu.
 * As for GetTree() but takes in a path rather than a sid.
 *
 * @param in_act	Access token.
 * @param in_sid_id The sid of the menu.
 * @param in_depth The depth to read to.
 *
 * The output rowset is of the form:
 * sid_id, name, attribute_list, level
 *
 * Where attribute_list is an XML style list of attributes (name="value" ...)
 */
PROCEDURE GetTreePath(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_menu_path	IN  security_pkg.T_SO_NAME,
	in_depth 		IN  NUMBER,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

/* LIST STUFF */

/**
 * GetList
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 * @param out_cur		The rowset
 */
PROCEDURE GetList(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_sid_id 		IN  security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

END Tree_Pkg;
/
