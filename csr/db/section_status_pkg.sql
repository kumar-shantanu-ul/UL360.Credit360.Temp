CREATE OR REPLACE PACKAGE  CSR.section_status_pkg
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

PROCEDURE CreateSectionStatus(
 	in_description							IN	section_status.description%TYPE,
	in_colour										IN	section_status.colour%TYPE,
	in_pos											IN	section_status.pos%TYPE,
	out_section_status_sid			OUT	security_pkg.T_SID_ID
);

PROCEDURE GetStatusesAndTransitions(
 	out_status_cur			OUT security_pkg.T_OUTPUT_CUR,
 	out_transition_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatusSummary(
	in_section_sid	IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END section_status_pkg;
/
