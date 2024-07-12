CREATE OR REPLACE PACKAGE  BODY DONATIONS.transition_pkg
IS

-- Securable object callbacks for donation status
PROCEDURE CreateObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID,
	in_class_id		IN security_pkg.T_CLASS_ID,
	in_name			IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
) AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
   DELETE FROM transition
	WHERE transition_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

PROCEDURE CreateTransition(
 	in_from_donation_status_sid		IN	donation_status.donation_status_sid%TYPE,
	in_to_donation_status_sid		IN	donation_status.donation_status_sid%TYPE,
	in_app_sid						IN  transition.app_sid%TYPE,
	out_transition_sid      		OUT	transition.transition_sid%TYPE
)
AS
	v_act_id      			security_pkg.T_ACT_ID;
	v_parent_sid			security_pkg.T_SID_ID;
	v_from_status_name		donation_status.description%TYPE;
	v_to_status_name		donation_status.description%TYPE;
BEGIN
	v_act_id  := security_pkg.GetAct();

	-- just do nothing if called with obvious wrong parameter
	IF in_from_donation_status_sid = in_to_donation_status_sid THEN
		RETURN;
	END IF;
		
	-- get names for SO object name
	SELECT description 
	  INTO v_from_status_name
	  FROM donation_status
	 WHERE donation_status_sid = in_from_donation_status_sid;
	
	SELECT description 
	  INTO v_to_status_name
	  FROM donation_status
	 WHERE donation_status_sid = in_to_donation_status_sid;
	 
	-- get securable object Donations/Status
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_app_sid, 'Donations/Transitions');
	SecurableObject_Pkg.CreateSO(v_act_id, v_parent_sid, class_pkg.getClassID('DonationsTransition'), v_from_status_name || '_' || v_to_status_name, out_transition_sid);
	
	INSERT INTO transition
		(transition_sid, from_donation_status_sid, to_donation_status_sid, app_sid)
	VALUES
		(out_transition_sid, in_from_donation_status_sid, in_to_donation_status_sid, in_app_sid);
END;

PROCEDURE CreateAutoTransitions(
 	in_from_donation_status_sid					IN	donation_status.donation_status_sid%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	v_transition_sid			security_pkg.T_SID_ID;
BEGIN
	v_app_sid := security_pkg.GetApp();

	-- create transitions from input status to rest of statuses
	FOR to_row IN (SELECT donation_status_sid FROM donation_status WHERE app_sid = v_app_sid)
	LOOP
		transition_pkg.createTransition(in_from_donation_status_sid, to_row.donation_status_sid, v_app_sid, v_transition_sid);		
		transition_pkg.createTransition(to_row.donation_status_sid, in_from_donation_status_sid, v_app_sid, v_transition_sid);			
	END LOOP;
END;
	
END transition_pkg;
/

