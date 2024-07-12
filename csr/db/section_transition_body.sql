CREATE OR REPLACE PACKAGE BODY  CSR.section_transition_pkg
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
   DELETE FROM SECTION_TRANSITION
          WHERE SECTION_TRANSITION_SID = in_sid_id;
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
 	in_from_section_status_sid					IN	security_pkg.T_SID_ID,
	in_to_section_status_sid						IN	security_pkg.T_SID_ID,
	out_transition_sid      						OUT	security_pkg.T_SID_ID
)
AS
  v_act_id      				security_pkg.T_ACT_ID;
	v_parent_sid					security_pkg.T_SID_ID;
	v_from_status_name		section_status.description%TYPE;
	v_to_status_name			section_status.description%TYPE;
BEGIN
  v_act_id  := SYS_CONTEXT('SECURITY','ACT');
	
	-- just do nothing if called with obvious wrong parameter
	IF in_from_section_status_sid = in_to_section_status_sid THEN
		RETURN;
	END IF;
		
	-- get names for SO object name
	SELECT description 
	  INTO v_from_status_name
	  FROM section_status
	 WHERE section_status_sid = in_from_section_status_sid;
	
	SELECT description 
	  INTO v_to_status_name
	  FROM section_status
	 WHERE section_status_sid = in_to_section_status_sid;
	 
	-- get securable object Donations/Status
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Text/Transitions');
	SecurableObject_Pkg.CreateSO(v_act_id, v_parent_sid, class_pkg.getClassID('SectionStatusTransition'), v_from_status_name || '_' || v_to_status_name, out_transition_sid);
	
	INSERT INTO SECTION_TRANSITION
		(section_transition_sid, from_section_status_sid, to_section_status_sid, app_sid)
	VALUES
		(out_transition_sid, in_from_section_status_sid, in_to_section_status_sid,  SYS_CONTEXT('SECURITY','APP'));
END;


PROCEDURE CreateAutoTransitions(
 	in_from_section_status_sid					IN	security_pkg.T_SID_ID
)
AS
	v_transition_sid			security_pkg.T_SID_ID;
BEGIN

	-- create transitions from input status to rest of statuses
	FOR to_row IN (SELECT section_status_sid FROM section_status WHERE app_sid = SYS_CONTEXT('SECURITY','APP'))
	LOOP
			section_transition_pkg.createTransition(in_from_section_status_sid, 	to_row.section_status_sid, v_transition_sid);		
			section_transition_pkg.createTransition(to_row.section_status_sid, 	in_from_section_status_sid, v_transition_sid);			
	END LOOP;
	
END;

END section_transition_pkg;
/

