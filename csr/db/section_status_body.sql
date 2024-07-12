CREATE OR REPLACE PACKAGE BODY  CSR.section_status_pkg
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
	UPDATE section_status 
	   SET description = in_new_name
	 WHERE section_status_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
    v_cnt   NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM section_module
	 WHERE default_status_sid = in_sid_id;
	
	IF v_cnt > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'One or more text modules uses this status as its default, so it cannot be deleted.');
	END IF; 
	
	-- set the section status to default one
	FOR r IN (
        SELECT default_status_sid, module_root_sid
          FROM section_module
         WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
    )
    LOOP
        UPDATE section 
           SET section_status_sid = r.default_status_sid
         WHERE module_root_sid = r.module_root_sid
           AND section_status_sid = in_sid_id;
    END LOOP;
          
	-- delete transitions which belongs to this object
	FOR r IN (
        SELECT section_transition_sid 
          FROM section_transition 
         WHERE from_section_status_sid = in_sid_id 
            OR to_section_status_sid = in_sid_id
    )
	LOOP
        securableobject_pkg.DeleteSO(in_act_id, r.section_transition_sid);
	END LOOP;

        
	-- delete status
	DELETE FROM section_status 
     WHERE section_status_sid  = in_sid_id;
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


PROCEDURE CreateSectionStatus(
 	in_description							IN	section_status.description%TYPE,
	in_colour										IN	section_status.colour%TYPE,
	in_pos											IN	section_status.pos%TYPE,
	out_section_status_sid			OUT	security_pkg.T_SID_ID
) AS
  v_act_id      security_pkg.T_ACT_ID;
  v_app_sid     security_pkg.T_SID_ID;
  v_parent_sid	security_pkg.T_SID_ID;
	
BEGIN
  v_act_id  := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
  
	-- get securable object Donations/Status
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Text/Statuses');
	
	SecurableObject_Pkg.CreateSO(v_act_id, v_parent_sid, class_pkg.getClassID('SectionStatus'), in_description, out_section_status_sid );
	
	INSERT INTO SECTION_STATUS
		(section_status_sid, app_sid, description, colour, pos)
	VALUES (
		out_section_status_sid , v_app_sid, in_description, in_colour, 
		(SELECT NVL(in_pos, NVL(MAX(POS),0)+1) FROM SECTION_STATUS WHERE APP_SID = v_app_sid)
	);
 		
	-- HACK
	-- it generates autotransitions always, we ought to 
	-- create a flag/attribute somewhere
	section_transition_pkg.CreateAutoTransitions(out_section_status_sid);
END;

PROCEDURE GetStatusesAndTransitions(
 	out_status_cur			OUT security_pkg.T_OUTPUT_CUR,
 	out_transition_cur		OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN	
	OPEN out_status_cur FOR
		SELECT section_status_sid, description, colour, pos, icon_path
		  FROM section_status
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	OPEN out_transition_cur FOR
		SELECT from_section_status_sid, to_section_status_sid
		  FROM section_transition
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), section_transition_sid, security_pkg.PERMISSION_READ) = 1 
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		 UNION	-- to include extra transition from self to self (ie. no change)
		SELECT distinct from_section_status_sid, from_section_status_sid
		  FROM section_transition
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), section_transition_sid, security_pkg.PERMISSION_READ) = 1 
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
END;



PROCEDURE GetStatusSummary(
	in_section_sid	IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

		OPEN out_cur FOR
	select section_status_sid, description, icon_path, colour, (
        select count(section_sid) 
          from section s 
         where s.section_status_sid = ss.section_status_sid
           AND s.title_only = 0
             AND CONNECT_BY_ISLEAF = 1
           START WITH section_sid in (
              SELECT sid_id FROM security.securable_object WHERE parent_sid_id = in_section_sid
           )
         CONNECT BY PRIOR section_sid = parent_sid 
      
      ) total_number 
      from section_status ss;
END;

END section_status_pkg;
/

