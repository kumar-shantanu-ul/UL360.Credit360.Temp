CREATE OR REPLACE PACKAGE  DONATIONS.status_Pkg
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


PROCEDURE CreateStatus(
 	in_description							IN	donation_status.description%TYPE,
	in_include_value_in_reports	IN	donation_status.include_value_in_reports%TYPE,
	in_means_paid								IN	donation_status.means_paid%TYPE,
	in_means_donated						IN	donation_status.means_donated%TYPE,
	in_pos											IN	donation_status.pos%TYPE,
	in_colour										IN	donation_status.colour%TYPE,
	out_donation_status_sid 		OUT	donation_status.donation_status_sid %TYPE
);

PROCEDURE UpdateDonationStatus(
	in_act_id										IN	security_pkg.T_ACT_ID,
	in_donation_status_sid				IN	donation_status.donation_Status_sid%TYPE,
	in_description							IN	donation_status.description%TYPE,
	in_include_value_in_reports	IN	donation_status.include_value_in_reports%TYPE,
	in_means_paid								IN	donation_status.means_paid%TYPE,
	in_means_donated								IN	donation_status.means_donated%TYPE,
	in_pos											IN	tag_group_member.pos%TYPE,
	in_colour										IN	donation_status.colour%TYPE
);

PROCEDURE RemoveDonationStatuses(
    in_donation_status_sids IN	VARCHAR2
);

PROCEDURE GetStatuses (
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_PKG.T_SID_ID,	
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatusesByStatus(
	in_status_sid		IN security_pkg.T_SID_ID,
	in_scheme_sid		IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStatus (
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_status_sid	IN	donation_status.donation_status_sid%TYPE,	
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CanSaveToStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_status_sid	IN	donation_status.donation_status_sid%TYPE,	
	out_can_save	OUT NUMBER
);

END status_pkg;
/

