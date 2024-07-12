CREATE OR REPLACE PACKAGE BODY  CSR.region_event_pkg AS

PROCEDURE AddEvent(
	in_region_sid			IN security_pkg.T_SID_ID,
	in_label					IN event.label%TYPE,
	in_event_text			IN event.event_text%TYPE,
	in_event_dtm			IN event.event_dtm%TYPE,
	out_cur		     		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID;
	v_act_id		security_pkg.T_ACT_ID;
	v_user_sid	security_pkg.T_SID_ID;
	v_event_id	security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_user_sid := security_pkg.GetSID();

	-- insert new event
	INSERT INTO event 
		(app_sid, event_id, label, raised_by_user_sid, raised_dtm, event_text, raised_for_region_sid, event_dtm)
	VALUES
		(v_app_sid, event_id_seq.nextval, in_label, v_user_sid, sysdate, in_event_text, in_region_sid, in_event_dtm)
	RETURNING event_id INTO v_event_id;
	
	
	-- associate with current region and all it's children
	INSERT INTO region_event (app_sid, region_sid, event_id)
			SELECT v_app_sid, region_sid, v_event_id 
				FROM region
	START WITH region_sid = in_region_sid
	 CONNECT BY PRIOR region_sid = parent_sid;
	 
	 -- return updated event
	GetEvent(v_event_id, in_region_sid, out_cur);
END;

PROCEDURE SetEvent(
	in_region_sid						IN security_pkg.T_SID_ID,
	in_event_id							IN security_pkg.T_SID_ID,
	in_label								IN event.label%TYPE,
	in_event_text						IN event.event_text%TYPE,
	in_event_dtm						IN event.event_dtm%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID();
	
	CheckOwner(in_event_id, in_region_sid);

	-- all fine, so update
	UPDATE event
	   SET event_text = in_event_text, 
				 label = in_label,
				 event_dtm = in_event_dtm
	  WHERE event_id = in_event_id
	    AND raised_by_user_sid = v_user_sid
	    AND raised_for_region_sid = in_region_sid;
	
END;

PROCEDURE GetEvents(
	in_region_sid			IN security_pkg.T_SID_ID,
	out_cur		     		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID;
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_user_sid := security_pkg.GetSID();

	OPEN out_cur FOR
		SELECT e.event_id, label, raised_dtm, event_dtm, raised_for_region_sid, event_text, r.description raised_for_region, CASE WHEN raised_for_region_sid = in_region_sid AND raised_by_user_sid = v_user_sid THEN 1 ELSE 0 END can_modify, cu.full_name raised_by
		  FROM event e, region_event re, v$region r, csr_user cu
		 WHERE re.event_id = e.event_id
		   AND cu.csr_user_sid = e.raised_by_user_sid
		   AND re.region_sid = in_region_sid
		   AND r.region_sid = e.raised_for_region_sid
		   AND e.app_sid = v_app_sid 
		 ORDER BY event_dtm DESC;
END;


PROCEDURE GetEvent(
	in_event_id 		IN security_pkg.T_SID_ID,
	in_region_sid 	IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID;
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_user_sid := security_pkg.GetSID();
	
	OPEN out_cur FOR
		SELECT e.event_id, label, raised_dtm, event_dtm, e.event_text, raised_for_region_sid, CASE WHEN raised_for_region_sid = in_region_sid AND raised_by_user_sid = v_user_sid THEN 1 ELSE 0 END can_modify, cu.full_name raised_by
				FROM event e, region_event re, csr_user cu
			 WHERE e.event_id = in_event_id
				 AND re.event_id = e.event_id
				 AND cu.csr_user_sid = e.raised_by_user_sid
				 AND re.region_sid = in_region_sid
				 AND e.app_sid = v_app_sid;
END;

PROCEDURE RemoveEvent(
	in_event_id							IN security_pkg.T_SID_ID,
	in_region_sid						IN security_pkg.T_SID_ID
)
AS
BEGIN
	CheckOwner(in_event_id, in_region_sid);
	
	-- TODO
	-- Do we want to delete all?  Maybe delete only on descendant of current region
	DELETE FROM REGION_EVENT
	 WHERE event_id = in_event_id;
	DELETE FROM EVENT 
	 WHERE event_id = in_event_id;
END;

PROCEDURE CheckOwner(
	in_event_id IN security_pkg.T_SID_ID,
	in_region_sid	IN security_pkg.T_SID_ID
)
AS
	v_cnt	NUMBER(10);
BEGIN
	-- seems harsh! Maybe needs a capability or something so that an admin could delete events?
	SELECT COUNT(*)
      INTO v_cnt
	  FROM event
	 WHERE event_id = in_event_id
	   AND raised_by_user_sid = security_pkg.GetSID()
	   AND raised_for_region_sid = in_region_sid;
	  
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Event with id: '||in_event_id||' does not belong to user sid '||security_pkg.GetSID());
	END IF;
END;

/*
 * When we add new region, we want to inherit all applicable events
 */
PROCEDURE InheritEvents(
	in_region_sid	IN security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO region_event 
		SELECT app_sid, in_region_sid, event_id FROM region_event WHERE region_sid = (
			SELECT parent_sid FROM region WHERE region_sid = in_region_sid
		);	
END;

END region_event_pkg;
/
