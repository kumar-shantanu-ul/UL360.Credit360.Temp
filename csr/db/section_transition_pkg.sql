CREATE OR REPLACE PACKAGE  CSR.section_transition_pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_new_name			IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);


PROCEDURE CreateTransition(
 	in_from_section_status_sid					IN	security_pkg.T_SID_ID,
	in_to_section_status_sid						IN	security_pkg.T_SID_ID,
	out_transition_sid      						OUT	security_pkg.T_SID_ID
);

PROCEDURE CreateAutoTransitions(
 	in_from_section_status_sid					IN	security_pkg.T_SID_ID
);

END section_transition_pkg;
/
