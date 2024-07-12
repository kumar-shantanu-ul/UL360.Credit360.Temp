CREATE OR REPLACE PACKAGE BODY	DONATIONS.status_Pkg
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
	UPDATE donation_status 
	   SET description = in_new_name
	 WHERE donation_status_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	
	-- delete transitions which belongs to this object
	FOR r IN (
		SELECT transition_sid 
		  FROM transition 
		 WHERE from_donation_status_sid = in_sid_id 
		    OR to_donation_status_sid = in_sid_id
	)
	LOOP
		securableobject_pkg.DeleteSO(in_act_id, r.transition_sid);
	END LOOP;
	
	DELETE FROM letter_body_region_group
	 WHERE donation_status_sid = in_sid_id;
			
	DELETE FROM letter_body_text 
	 WHERE donation_status_sid = in_sid_id;
			
	DELETE FROM donation_status 
	 WHERE donation_status_sid = in_sid_id;
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


PROCEDURE CreateStatus(
 	in_description					IN	donation_status.description%TYPE,
	in_include_value_in_reports		IN	donation_status.include_value_in_reports%TYPE,
	in_means_paid					IN	donation_status.means_paid%TYPE,
	in_means_donated				IN	donation_status.means_donated%TYPE,
	in_pos							IN	donation_status.pos%TYPE,
	in_colour						IN	donation_status.colour%TYPE,
	out_donation_status_sid			OUT	donation_status.donation_status_sid %TYPE
) AS
	v_act_id			security_pkg.T_ACT_ID;
	v_app_sid		 	security_pkg.T_SID_ID;
	v_parent_sid		security_pkg.T_SID_ID;
	v_auto_transitions	NUMBER;
BEGIN
	v_act_id  := security_pkg.GetAct();
	v_app_sid := security_pkg.GetApp();
	
	-- get securable object Donations/Status
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Donations/Statuses');
	
	SecurableObject_Pkg.CreateSO(v_act_id, v_parent_sid, class_pkg.getClassID('DonationsStatus'), in_description, out_donation_status_sid );
	
	INSERT INTO DONATION_STATUS
		(donation_status_sid , app_sid, description, include_value_in_reports, 
		means_paid, means_donated, colour, pos)
	VALUES
		(out_donation_status_sid, v_app_sid, in_description, in_include_value_in_reports,
		in_means_paid, in_means_donated, in_colour,
		(SELECT NVL(in_pos, NVL(MAX(POS),0)+1) FROM DONATION_STATUS WHERE APP_SID = v_app_sid));
	
	-- check if we should generate transitions for status
	SELECT CASE WHEN auto_gen_status_transition > 0 THEN 1 ELSE 0 END 
		INTO v_auto_transitions 
		FROM customer_filter_flag 
		WHERE app_sid = v_app_sid;
	
	-- generate transitions for new status	
	IF v_auto_transitions = 1 THEN
		transition_pkg.CreateAutoTransitions(out_donation_status_sid);
	END IF;
		
END;

PROCEDURE RemoveDonationStatuses(
	in_donation_status_sids IN	VARCHAR2
)
AS
	v_act_id			security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	v_act_id 			:= security_pkg.GetACT();
	v_app_sid			:= security_pkg.GetApp();
	
	FOR r IN (
		SELECT donation_status_sid 
		  FROM donation_status 
		 WHERE app_sid = v_app_sid 
		   AND donation_status_sid NOT IN (
				SELECT item
				  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_donation_status_sids,','))
			)
	)
	LOOP
		securableobject_pkg.DeleteSO(v_act_id, r.donation_status_sid);
	END LOOP;
END;



PROCEDURE UpdateDonationStatus(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_donation_status_sid			IN	donation_status.donation_Status_sid%TYPE,
	in_description					IN	donation_status.description%TYPE,
	in_include_value_in_reports		IN	donation_status.include_value_in_reports%TYPE,
	in_means_paid					IN	donation_status.means_paid%TYPE,
	in_means_donated				IN	donation_status.means_donated%TYPE,
	in_pos							IN	tag_group_member.pos%TYPE,
	in_colour						IN	donation_status.colour%TYPE
)
AS
BEGIN

	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_donation_status_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied change donation status');
	END IF;
	
	-- update status
	UPDATE donation_status
		 SET description = in_description,
			include_Value_in_reports = in_include_Value_in_reports,
			means_paid = in_means_paid,
			means_donated = in_means_donated,
			pos = in_pos,
			colour = in_colour
	 WHERE donation_status_sid = in_donation_status_sid;				

END;

-- 
-- PROCEDURE: GetStatuses
--
PROCEDURE GetStatuses (
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_PKG.T_SID_ID,	
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	OPEN out_cur FOR
		SELECT donation_status_sid, pos, description, include_value_in_reports, means_paid, means_donated, 
			colour, show_for_new_donation, warning_msg
		  FROM donation_status ds
		 WHERE ds.app_sid = in_app_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, donation_status_sid , security_pkg.PERMISSION_READ) = 1
		 ORDER BY pos;
END;


-- 
-- PROCEDURE: GetStatusesByStatus
--
PROCEDURE GetStatusesByStatus(
	in_status_sid		IN security_pkg.T_SID_ID,
	in_scheme_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_act_id			security_pkg.T_ACT_ID;
BEGIN
	v_app_sid 	:= SYS_CONTEXT('SECURITY', 'APP');
	v_act_id	:= SYS_CONTEXT('SECURITY', 'ACT');
 
	-- return full set of statuses if status sid is not provided (we check permissions if anybody wants to save with incorrect status anyway)
	-- if status_sid provided then return only these statuses which are applicable (by transition)
	
 	IF in_status_sid IS NOT NULL AND in_status_sid != -1	THEN
		OPEN out_cur FOR
			-- get all possible steps using transition
			SELECT ds.donation_status_sid, pos, description, include_value_in_reports, means_paid, means_donated, 
				colour, show_for_new_donation, warning_msg
			  FROM donation_status ds, scheme_donation_status sds
			 WHERE ds.donation_status_sid IN (
					SELECT to_donation_status_sid 
					  FROM transition 
					 WHERE from_donation_status_sid = in_status_sid
					   AND app_sid = v_app_sid
					   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, transition_sid, security_pkg.PERMISSION_READ) = 1
			   )
			   AND sds.scheme_sid = in_scheme_sid
			   AND ds.donation_status_sid = sds.donation_status_sid
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, ds.donation_status_sid, security_pkg.PERMISSION_WRITE) = 1		
			-- include the current status as well
			UNION 
			SELECT donation_status_sid, pos, description, include_value_in_reports, means_paid, means_donated, 
				colour, show_for_new_donation, warning_msg
			  FROM donation_status ds
			 WHERE donation_status_sid	= in_status_sid
			 ORDER BY POS;
	ELSE 
		OPEN out_cur FOR
			-- get all statuses for particular scheme
			SELECT ds.donation_status_sid, pos, description, include_value_in_reports, means_paid, means_donated, 
				colour, show_for_new_donation, warning_msg
			  FROM donation_status ds, scheme_donation_status sds
			 WHERE ds.app_sid = v_app_sid
			   AND ds.donation_status_sid = sds.donation_status_sid
			   AND sds.scheme_sid = in_scheme_sid
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, ds.donation_status_sid, security_pkg.PERMISSION_WRITE) = 1
			 ORDER BY pos;			
	END IF;
END;

PROCEDURE GetStatus (
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_status_sid	IN	donation_status.donation_status_sid%TYPE,	
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT donation_Status_sid, pos, description, include_value_in_reports, means_paid, 
			means_donated, colour, show_for_new_donation, warning_msg
		  FROM donation_status
		 WHERE donation_status_sid = in_status_sid;
END;


PROCEDURE CanSaveToStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_status_sid	IN	donation_status.donation_status_sid%TYPE,	
	out_can_save	OUT NUMBER
)
AS
BEGIN
	SELECT 
		CASE 
			WHEN security_pkg.SQL_IsAccessAllowedSID(in_act_id, in_status_sid , security_pkg.PERMISSION_WRITE) = 1 THEN 1 
			ELSE 0 	
		END can_save 
	  INTO out_can_save
	  FROM DUAL;
END;

END status_pkg;
/




