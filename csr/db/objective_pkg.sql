CREATE OR REPLACE PACKAGE CSR.Objective_Pkg AS

-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * CopyObjective
 * 
 * @param in_act_id				Access token
 * @param in_parent_sid_id		The sid of the parent object of the new object
 * @param in_sid_id				The sid of the object to copy
 */
PROCEDURE CopyObjective(
	in_act_id         IN  security_pkg.t_act_id,
	in_parent_sid_id  IN  security_pkg.t_sid_id,
	in_sid_id         IN  security_pkg.t_sid_id
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

/**
 * Create a new objective
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param	in_name					Name
 * @param	in_description			Description
 * @param	in_responsible_user_sid	Responsible user sid
 * @param	in_delivery_user_sid	Delivery user sid
 * @param	in_xml_template			XML template				 
 * @param	in_pos					Pos
 * @param	out_objective_sid		The SID of the created object
 *
 */
PROCEDURE CreateObjective(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_parent_sid_id			IN security_pkg.T_SID_ID, 
	in_name						IN OBJECTIVE.NAME%TYPE,
	in_description				IN OBJECTIVE.description%TYPE,
	in_responsible_user_sid		IN OBJECTIVE.responsible_user_sid%TYPE,
	in_delivery_user_sid		IN OBJECTIVE.delivery_user_sid%TYPE,
	in_xml_template				IN OBJECTIVE.xml_template%TYPE,
	in_pos						IN OBJECTIVE.pos%TYPE,
	out_objective_sid			OUT OBJECTIVE.objective_sid%TYPE
);

/**
 * Update a objective
 *
 * @param	in_act_id				Access token
 * @param	in_objective_sid		The objective to update
 * @param	in_name					The new objective name
 * @param	in_description			The new objective description
 * @param	in_responsible_user_sid	The new user responsible for this
 * @param	in_delivery_user_sid	The new user delivering this
 * @param	in_xml_template			xml template for meta data
 * @param	in_pos					Pos
 */
PROCEDURE UpdateObjective(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_objective_sid		IN security_pkg.T_SID_ID,
	in_name						IN OBJECTIVE.NAME%TYPE,
	in_description				IN OBJECTIVE.description%TYPE,
	in_responsible_user_sid		IN OBJECTIVE.responsible_user_sid%TYPE,
	in_delivery_user_sid		IN OBJECTIVE.delivery_user_sid%TYPE,
	in_xml_template				IN OBJECTIVE.xml_template%TYPE,
	in_pos						IN OBJECTIVE.pos%TYPE
);							 
		
/**
 * SetStatus
 * 
 * @param in_act_id					Access token
 * @param in_objective_sid			.
 * @param in_start_dtm				The start date
 * @param in_end_dtm				The end date
 * @param in_score					.
 * @param in_status_description		.
 * @param in_status_xml				.
 */
PROCEDURE SetStatus(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_objective_sid			IN security_pkg.T_SID_ID,
	in_start_dtm				IN OBJECTIVE_STATUS.start_dtm%TYPE,
	in_end_dtm					IN OBJECTIVE_STATUS.end_dtm%TYPE,
	in_score					IN OBJECTIVE_STATUS.score%TYPE,
	in_status_description		IN OBJECTIVE_STATUS.status_description%TYPE,
	in_status_xml				IN OBJECTIVE_STATUS.status_xml%TYPE
);
/**
 * GetObjective
 * 
 * @param in_act_id				Access token
 * @param in_objective_sid		.
 * @param out_cur				The rowset
 */
PROCEDURE GetObjective(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_objective_sid	IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

/**
 * GetObjectiveAndStatus
 * 
 * @param in_act_id				Access token
 * @param in_objective_sid		.
 * @param in_start_dtm			The start date
 * @param in_end_dtm			The end date
 * @param out_cur				The rowset
 */
PROCEDURE GetObjectiveAndStatus(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_objective_sid	IN security_pkg.T_SID_ID, 		   
	in_start_dtm		IN OBJECTIVE_STATUS.start_dtm%TYPE,
	in_end_dtm			IN OBJECTIVE_STATUS.end_dtm%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

/**
 * GetChildObjectivesAndStatus
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param out_cur			The rowset
 */
PROCEDURE GetChildObjectivesAndStatus(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID, 		   
	in_start_dtm		IN OBJECTIVE_STATUS.start_dtm%TYPE,
	in_end_dtm			IN OBJECTIVE_STATUS.end_dtm%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);


/**
 * Rolls forward last quarter's objectives to quarter before the 
 * one we're currently in. If the date is 5 Jan 2007, it will
 * make sure that quarter to end of December is populated. 
 *
 * NB This only works with quarters aligned to January, i.e. 
 * year start of Feb will not work properly
 * 
 * @param in_root_sid		The sid of the parent object
 */
PROCEDURE RollForwardObjectives(
	in_root_sid			IN security_pkg.T_SID_ID
);

END Objective_Pkg;
/
