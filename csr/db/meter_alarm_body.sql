CREATE OR REPLACE PACKAGE BODY CSR.meter_alarm_pkg IS

FUNCTION INTERNAL_GetIssueMeterLabel(
    in_region_sid	IN	security_pkg.T_SID_ID
)
RETURN VARCHAR2
AS
    v_country		VARCHAR2(1024);
    v_desc			VARCHAR2(1024);
BEGIN
	BEGIN
		SELECT pc.name || ', '
		  INTO v_country
		  FROM postcode.country pc, region r
		 WHERE r.region_sid = in_region_sid
		   AND pc.country = r.geo_country;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_country := '';
	END;
	
	SELECT description
	  INTO v_desc
	  FROM v$region
	 WHERE region_sid = in_region_sid;
	
	RETURN v_country || meter_pkg.INTERNAL_GetProperty(in_region_sid) || ', ' || v_desc;
	
END;

PROCEDURE InheritAlarmsFromParent(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;
	
	-- Get parent, resolving if it's a link
	BEGIN
		SELECT NVL(p.link_to_region_sid, p.region_sid)
		  INTO v_parent_sid
		  FROM region c, region p
		 WHERE c.region_sid = in_region_sid
		   AND p.region_sid = c.parent_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- No parent, nothing to ihherit
			RETURN;
	END;
	
	-- Inherit alarms from parent
	FOR r IN (
		SELECT rma.meter_alarm_id, rma.ignore_children, rma.inherited_from_sid
		  FROM region_meter_alarm rma, region rgn, meter_alarm ma
		 WHERE ma.meter_alarm_id = rma.meter_alarm_id
		   AND ma.inheritable = 1
		   AND rgn.region_sid = v_parent_sid
		   AND rma.region_sid = NVL(rgn.link_to_region_sid, rgn.region_sid)
	) LOOP
		BEGIN
			INSERT INTO region_meter_alarm
			  (meter_alarm_id, ignore, ignore_children, inherited_from_sid, region_sid)
				SELECT r.meter_alarm_id, r.ignore_children, r.ignore_children, r.inherited_from_sid, NVL(link_to_region_sid, region_sid)
				  FROM region
				  	START WITH region_sid = in_region_sid
				  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;
				
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE region_meter_alarm
				   SET ignore = r.ignore_children,
				       ignore_children = r.ignore_children,
				       inherited_from_sid = r.inherited_from_sid
				 WHERE meter_alarm_id = r.meter_alarm_id
				   AND region_sid IN (
				   	SELECT NVL(link_to_region_sid, region_sid)
					  FROM region
					  	START WITH region_sid = in_region_sid
					  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				   );
		END;
	END LOOP;
END;

PROCEDURE RemoveInheritedAlarms(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE DEFAULT NULL
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;
	
	-- Resolve links
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	-- remove _inherited_ alarms from this node and all it's children
	DELETE FROM region_meter_alarm
	 WHERE meter_alarm_id = NVL(in_alarm_id, meter_alarm_id)
	   AND region_sid IN (
	 	SELECT NVL(link_to_region_sid, region_sid)
	 	  FROM region
	 	  	START WITH region_sid = in_region_sid
	 	  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	 )
	   AND inherited_from_sid IN (
		SELECT inherited_from_sid
		  FROM region_meter_alarm
		 WHERE region_sid = v_region_sid
		   --AND region_sid <> inherited_from_sid -- ensure we don't remove alarms originating at this node level
		   AND inherited_from_sid NOT IN (
			SELECT 
				region_sid
			FROM
				region
				START WITH region_sid = in_region_sid
				CONNECT BY region_sid = PRIOR parent_sid
		   ) -- exclude alarms that are still in the inheritance tree
	 );
END;

PROCEDURE PropagateAlarms(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;

	-- The rule is that we always resolve links before applying alarms 
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	-- Propagate
	FOR r IN (
		SELECT rma.meter_alarm_id, rma.ignore_children, rma.inherited_from_sid
		  FROM region_meter_alarm rma, meter_alarm ma
		 WHERE ma.meter_alarm_id = rma.meter_alarm_id
		   AND rma.region_sid = v_region_sid
		   AND ma.inheritable = 1
	) LOOP
		BEGIN
			INSERT INTO region_meter_alarm
			  (meter_alarm_id, ignore, ignore_children, inherited_from_sid, region_sid)
				SELECT r.meter_alarm_id, r.ignore_children, r.ignore_children, r.inherited_from_sid, NVL(link_to_region_sid, region_sid)
				  FROM region
				  	START WITH parent_sid = v_region_sid
				  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;
				
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE region_meter_alarm
				   SET ignore = r.ignore_children,
				       ignore_children = r.ignore_children,
				       inherited_from_sid = r.inherited_from_sid
				 WHERE meter_alarm_id = r.meter_alarm_id
				   AND region_sid IN (
				   		SELECT NVL(link_to_region_sid, region_sid)
						  FROM region
						  	START WITH parent_sid = v_region_sid
						  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				 );
		END;
	END LOOP;
END;

PROCEDURE OnNewRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	InheritAlarmsFromParent(in_region_sid);
	meter_alarm_stat_pkg.AssignStatistics(in_region_sid);
END;

PROCEDURE OnMoveRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	RemoveInheritedAlarms(in_region_sid);
	InheritAlarmsFromParent(in_region_sid);
	meter_alarm_stat_pkg.AssignStatistics(in_region_sid);
END;

PROCEDURE OnCopyRegion(
	in_from_region_sid		IN	security_pkg.T_SID_ID,
	in_new_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_from_sid				security_pkg.T_SID_ID;
	v_new_sid				security_pkg.T_SID_ID;
BEGIN
	-- Remove any inherited alarms
	RemoveInheritedAlarms(in_new_region_sid);

	-- Resolve links for copy
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_from_sid
	  FROM region
	 WHERE region_sid = in_from_region_sid;

	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_new_sid
	  FROM region
	 WHERE region_sid = in_new_region_sid;

	-- Copy alarms at the from region level
	INSERT INTO region_meter_alarm
		(meter_alarm_id, ignore, ignore_children, inherited_from_sid, region_sid)
		SELECT meter_alarm_id, ignore, ignore_children, v_new_sid, v_new_sid
		  FROM region_meter_alarm
		 WHERE region_sid = v_from_sid
		   AND inherited_from_sid = v_from_sid;
	
	-- Propgate any copied alarms
	PropagateAlarms(in_new_region_sid);
	
	-- Inherit alarms from new parent
	InheritAlarmsFromParent(in_new_region_sid);
	
	-- Assign required statistics to all meters under this region
	meter_alarm_stat_pkg.AssignStatistics(in_new_region_sid);
END;

PROCEDURE OnDeleteRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT issue_id
		  FROM csr.issue i, csr.issue_meter_alarm im
		 WHERE i.issue_meter_alarm_id = im.issue_meter_alarm_id
		   AND im.region_sid = in_region_sid
	) LOOP	
		csr.issue_pkg.UNSEC_DeleteIssue(r.issue_id);
	END LOOP;
	
	DELETE FROM issue_meter_alarm
	 WHERE region_sid = in_region_sid;
	
	DELETE FROM meter_alarm_event
	 WHERE region_sid = in_region_sid;
	
	DELETE FROM meter_alarm_statistic_job
	 WHERE region_sid = in_region_sid;
	 
	DELETE FROM meter_alarm_statistic_period
	  WHERE region_sid = in_region_sid;
	  
	DELETE FROM meter_alarm_stat_run
	 WHERE region_sid = in_region_sid;
	
	DELETE FROM meter_meter_alarm_statistic
	 WHERE region_sid = in_region_sid;
	
	DELETE FROM region_meter_alarm
	 WHERE region_sid = in_region_sid
	    OR inherited_from_sid = in_region_sid;
END;

PROCEDURE OnTrashRegion(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM meter_alarm_statistic_job
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE OnConvertRegionToLink(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	InheritAlarmsFromParent(in_region_sid);
	meter_alarm_stat_pkg.AssignStatistics(in_region_sid);
END;

PROCEDURE AssignAlarmToRegion(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_ignore				IN	region_meter_alarm.ignore%TYPE,
	in_ignore_children		IN	region_meter_alarm.ignore_children%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;
	
	-- The rule is that we always resolve links before applying alarms 
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	-- Associate the alarm with the region (inherited from sid == region sid -> top level)
	BEGIN
		INSERT INTO region_meter_alarm
			(region_sid, meter_alarm_id, inherited_from_sid, ignore, ignore_children)
		  VALUES (in_region_sid, in_alarm_id, v_region_sid, in_ignore, in_ignore_children);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE region_meter_alarm
			   SET inherited_from_sid = v_region_sid,
			       ignore = in_ignore,
			       ignore_children = in_ignore_children
			 WHERE meter_alarm_id = in_alarm_id
			   AND region_sid = v_region_sid;
	END;
	
	-- Propagate the alarm down the region tree
	PropagateAlarms(v_region_sid);
	
	-- Assign required statistics to all meters under this region
	meter_alarm_stat_pkg.AssignStatistics(v_region_sid);
END;

PROCEDURE SetAlarm(
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_inheritable			IN	meter_alarm.inheritable%TYPE,
	in_enabled				IN	meter_alarm.enabled%TYPE,
	in_name					IN	meter_alarm.name%TYPE,
	in_test_time_id			IN	meter_alarm.test_time_id%TYPE,
	in_look_at_stat_id		IN	meter_alarm.look_at_statistic_id%TYPE,
	in_comp_stat_id			IN	meter_alarm.compare_statistic_id%TYPE,
	in_comp_id				IN	meter_alarm.comparison_id%TYPE,
	in_comp_val				IN	meter_alarm.comparison_val%TYPE,
	in_issue_period_id		IN	meter_alarm.issue_period_id%TYPE,
	in_issue_trigger_cnt	IN	meter_alarm.issue_trigger_count%TYPE,
	out_alarm_id			OUT	meter_alarm.meter_alarm_id%TYPE
)
AS
BEGIN
	IF NVL(in_alarm_id, -1) = -1 THEN
		INSERT INTO meter_alarm
			(meter_alarm_id, inheritable, enabled, name, test_time_id, look_at_statistic_id, 
				compare_statistic_id, comparison_id, comparison_val, issue_period_id, issue_trigger_count)
		  VALUES (meter_alarm_id_seq.NEXTVAL, in_inheritable, in_enabled, in_name, in_test_time_id, in_look_at_stat_id, 
		  		in_comp_stat_id, in_comp_id, in_comp_val, in_issue_period_id, in_issue_trigger_cnt)
		  	RETURNING meter_alarm_id INTO out_alarm_id;
	ELSE
		out_alarm_id := in_alarm_id;
		UPDATE meter_alarm
		   SET inheritable = in_inheritable,
		   	   enabled = in_enabled,
		   	   name = in_name,
		   	   test_time_id = in_test_time_id,
		   	   look_at_statistic_id = in_look_at_stat_id, 
			   compare_statistic_id = in_comp_stat_id,
			   comparison_id = in_comp_id,
			   comparison_val = in_comp_val,
			   issue_period_id = in_issue_period_id,
			   issue_trigger_count = in_issue_trigger_cnt
		 WHERE meter_alarm_id = in_alarm_id;
	END IF;
END;

PROCEDURE SetAlarmForRegion(
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_inheritable			IN	meter_alarm.inheritable%TYPE,
	in_enabled				IN	meter_alarm.enabled%TYPE,
	in_name					IN	meter_alarm.name%TYPE,
	in_test_time_id			IN	meter_alarm.test_time_id%TYPE,
	in_look_at_stat_id		IN	meter_alarm.look_at_statistic_id%TYPE,
	in_comp_stat_id			IN	meter_alarm.compare_statistic_id%TYPE,
	in_comp_id				IN	meter_alarm.comparison_id%TYPE,
	in_comp_val				IN	meter_alarm.comparison_val%TYPE,
	in_issue_period_id		IN	meter_alarm.issue_period_id%TYPE,
	in_issue_trigger_cnt	IN	meter_alarm.issue_trigger_count%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_ignore				IN	region_meter_alarm.ignore%TYPE,
	in_ignore_children		IN	region_meter_alarm.ignore_children%TYPE,
	out_alarm_id			OUT	meter_alarm.meter_alarm_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;
	
	-- Create a new alarm
	SetAlarm(in_alarm_id, in_inheritable, in_enabled, in_name, in_test_time_id, in_look_at_stat_id, 
		in_comp_stat_id, in_comp_id, in_comp_val, in_issue_period_id, in_issue_trigger_cnt, out_alarm_id);
	
	-- Assign the alam to the region
	AssignAlarmToRegion(in_region_sid, out_alarm_id, in_ignore, in_ignore_children);
END;

PROCEDURE SetInheritable(
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_inheritable			IN	meter_alarm.inheritable%TYPE
)
AS
BEGIN
	-- Set inheritable flag on alarm
	UPDATE meter_alarm
	   SET inheritable = in_inheritable
	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Update any regions using this alarm
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid IN (
		 	SELECT region_sid
		 	  FROM region_meter_alarm
		 	 WHERE meter_alarm_id = in_alarm_id
		 	   AND region_sid = inherited_from_sid
		 )
	) LOOP
		IF in_inheritable = 0 THEN
			-- Remove inherited alarms with this id from all children of 
			-- any region that is at the top level for this alarm
			RemoveInheritedAlarms(r.region_sid, in_alarm_id);
			meter_alarm_stat_pkg.AssignStatistics(r.region_sid);
		ELSE
			-- We've set the inheritable flag to '1' so just 
			-- propogating will ensure coreect inheritance
			PropagateAlarms(r.region_sid);
			meter_alarm_stat_pkg.AssignStatistics(r.region_sid);
		END IF;
	END LOOP;
END;

PROCEDURE SetIgnore(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_ignore				IN	region_meter_alarm.ignore%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF; 
	
	-- The rule is that we always resolve links before applying alarms 
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	UPDATE region_meter_alarm
	  SET ignore = in_ignore
	WHERE region_sid = v_region_sid
	  AND meter_alarm_id = in_alarm_id;
	  
	-- Assign required statistics to all meters under this region
	meter_alarm_stat_pkg.AssignStatistics(v_region_sid);
END;

PROCEDURE SetIgnoreChildren(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_ignore_children		IN	region_meter_alarm.ignore_children%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;
	
	-- The rule is that we always resolve links before applying alarms 
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	UPDATE region_meter_alarm
	  SET ignore_children = in_ignore_children
	WHERE region_sid = v_region_sid
	  AND meter_alarm_id = in_alarm_id;
	  
	PropagateAlarms(v_region_sid);
	
	-- Assign required statistics to all meters under this region
	meter_alarm_stat_pkg.AssignStatistics(v_region_sid);
END;

PROCEDURE RemoveAlarm(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE
)
AS
	v_count					NUMBER;
	look_at_stat_id			meter_alarm_statistic.statistic_id%TYPE;
	compare_stat_id			meter_alarm_statistic.statistic_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on region with sid '||in_region_sid);
	END IF;
	
	DELETE FROM meter_alarm_event
	 WHERE meter_alarm_id = in_alarm_id
	   AND region_sid IN (
	   		SELECT region_sid
	   		  FROM region_meter_alarm
	   		 WHERE inherited_from_sid = in_region_sid
	   );
	
	DELETE FROM region_meter_alarm
	 WHERE inherited_from_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id;
	
	SELECT look_at_statistic_id, compare_statistic_id
  	  INTO look_at_stat_id, compare_stat_id
  	  FROM meter_alarm
  	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Delete any outstanding jobs
	DELETE FROM meter_alarm_statistic_job
	 WHERE region_sid = in_region_sid
	   AND statistic_id IN (look_at_stat_id, compare_stat_id);
		 
	-- Delete any associated run info
	DELETE FROM meter_alarm_stat_run
	 WHERE region_sid = in_region_sid
	   AND statistic_id IN (look_at_stat_id, compare_stat_id);
	 
	-- Delete stat data
	DELETE FROM meter_alarm_statistic_period
	 WHERE region_sid = in_region_sid
	   AND statistic_id IN (look_at_stat_id, compare_stat_id);
	 
	-- Delete meter/stat relationship
	DELETE FROM meter_meter_alarm_statistic
	 WHERE region_sid = in_region_sid
	   AND statistic_id IN (look_at_stat_id, compare_stat_id);

	-- XXX: We can't delete the alarm without deleting any related open, 
	-- issues, the meter still exists so we probably ought not do that.
	/*
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	
	IF v_count = 0 THEN
		DELETE FROM meter_alarm
		  WHERE meter_alarm_id = in_alarm_id;
	END IF;
	*/
	
	-- Assign required statistics to all meters under this region
	meter_alarm_stat_pkg.AssignStatistics(in_region_sid);
END;

PROCEDURE GetAlarm (
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT meter_alarm_id, name, inheritable, enabled, test_time_id, look_at_statistic_id, 
			compare_statistic_id, comparison_id, comparison_val,  issue_period_id, issue_trigger_count
		  FROM meter_alarm
		 WHERE meter_alarm_id = in_alarm_id;
END;

PROCEDURE GetAlarmsForRegion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on region with sid '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT rma.region_sid, rma.meter_alarm_id, rma.inherited_from_sid, rma.ignore, rma.ignore_children, DECODE(rma.region_sid, rma.inherited_from_sid, 0, 1) inherited,
			   ma.name, ma.inheritable, ma.enabled, ma.test_time_id, ma.look_at_statistic_id, ma.compare_statistic_id, ma.comparison_id, ma.comparison_val, ma.issue_period_id, ma.issue_trigger_count,
			   trgn.description region_desc, irgn.description inherited_from_desc
		  FROM region_meter_alarm rma, meter_alarm ma, v$region trgn, v$region irgn
		 WHERE rma.region_sid = in_region_sid
		   AND ma.meter_alarm_id = rma.meter_alarm_id
		   AND trgn.region_sid = rma.region_sid
		   AND irgn.region_sid = rma.inherited_from_sid;
END;

PROCEDURE GetAlarmsForRegion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_inherited			OUT	security_pkg.T_OUTPUT_CUR,
	out_this_level			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on region with sid '||in_region_sid);
	END IF;
	
	OPEN out_inherited FOR
		SELECT rma.region_sid, rma.meter_alarm_id, rma.inherited_from_sid, rma.ignore, rma.ignore_children, 1 inherited,
			   ma.name, ma.inheritable, ma.enabled, ma.test_time_id, ma.look_at_statistic_id, ma.compare_statistic_id,
			   ma.comparison_id, ma.comparison_val, ma.issue_period_id, ma.issue_trigger_count,
			   trgn.description region_desc, irgn.description inherited_from_desc
		  FROM region_meter_alarm rma
		  JOIN meter_alarm ma ON ma.meter_alarm_id = rma.meter_alarm_id
		  JOIN v$region trgn ON trgn.region_sid = rma.region_sid
		  JOIN v$region irgn ON irgn.region_sid = rma.inherited_from_sid
		 WHERE rma.region_sid = in_region_sid
		   AND rma.region_sid != rma.inherited_from_sid
		   AND rma.ignore = 0;

	OPEN out_this_level FOR
		SELECT rma.region_sid, rma.meter_alarm_id, rma.inherited_from_sid, rma.ignore, rma.ignore_children, 0 inherited,
			   ma.name, ma.inheritable, ma.enabled, ma.test_time_id, ma.look_at_statistic_id, ma.compare_statistic_id, ma.comparison_id,
			   ma.comparison_val, ma.issue_period_id, ma.issue_trigger_count,
			   trgn.description region_desc, irgn.description inherited_from_desc
		  FROM region_meter_alarm rma
		  JOIN meter_alarm ma ON ma.meter_alarm_id = rma.meter_alarm_id
		  JOIN v$region trgn ON trgn.region_sid = rma.region_sid
		  JOIN v$region irgn ON irgn.region_sid = rma.inherited_from_sid
		 WHERE rma.region_sid = in_region_sid
		   AND rma.region_sid = rma.inherited_from_sid;
END;

PROCEDURE GetActiveAlarms(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on region with sid '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT rma.region_sid, rma.meter_alarm_id, rma.inherited_from_sid, rma.ignore, rma.ignore_children, DECODE(rma.region_sid, rma.inherited_from_sid, 0, 1) inherited,
			   ma.name, ma.inheritable, trgn.description region_desc, irgn.description inherited_from_desc
		  FROM region_meter_alarm rma, meter_alarm ma, v$region trgn, v$region irgn
		 WHERE rma.region_sid = in_region_sid
		   AND ma.meter_alarm_id = rma.meter_alarm_id
		   AND trgn.region_sid = rma.region_sid
		   AND irgn.region_sid = rma.inherited_from_sid
		   AND rma.ignore = 0
		   AND ma.enabled = 1;
END;

PROCEDURE GetComparisons(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT comparison_id, name, show_pct, op_code
		  FROM meter_alarm_comparison
		 WHERE app_sid = security_pkg.GetAPP;
END;

PROCEDURE GetTestTimes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT test_time_id, name, test_function
		  FROM meter_alarm_test_time
		 WHERE app_sid = security_pkg.GetAPP;
END;

PROCEDURE GetIssuePeriods(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT issue_period_id, name, test_function
		  FROM meter_alarm_issue_period
		 WHERE app_sid = security_pkg.GetAPP;
END;

PROCEDURE GetStatistics(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT statistic_id, name, is_average, is_sum, comp_proc
		  FROM meter_alarm_statistic
		 WHERE app_sid = security_pkg.GetAPP
		 ORDER BY pos, statistic_id;
END;

PROCEDURE GetAlarmDlgOptions (
	out_comparisons			OUT	security_pkg.T_OUTPUT_CUR,
	out_test_times			OUT	security_pkg.T_OUTPUT_CUR,
	out_issue_periods		OUT	security_pkg.T_OUTPUT_CUR,
	out_statistics			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetComparisons(out_comparisons);
	GetTestTimes(out_test_times);
	GetIssuePeriods(out_issue_periods);
	GetStatistics(out_statistics);
END;

PROCEDURE AddAlarmEvent (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_data_dtm				IN	DATE
)
AS
	v_raise					NUMBER;
	v_meter_alarm_name		meter_alarm.name%TYPE;
	v_test_fn				meter_alarm_issue_period.test_function%TYPE;
	v_issue_id				issue.issue_id%TYPE;
	v_out_cur				security_pkg.T_OUTPUT_CUR;
	v_create				BOOLEAN;
BEGIN
	-- Fetch some info
	SELECT ma.name, ip.test_function
	  INTO v_meter_alarm_name, v_test_fn
	  FROM meter_alarm ma, meter_alarm_issue_period ip
	 WHERE meter_alarm_id = in_alarm_id
	   AND ip.issue_period_id = ma.issue_period_id;
	
	-- Insert the event
	INSERT INTO meter_alarm_event
	  (region_sid, meter_alarm_id, meter_alarm_event_id, event_dtm)
	  	VALUES (in_region_sid, in_alarm_id, meter_alarm_event_id_seq.NEXTVAL, in_data_dtm);
	  	
	-- Check to see if we need to raise an issue
	EXECUTE IMMEDIATE 'BEGIN '||v_test_fn||'(:1,:2,:3,:4);END;'
		USING in_region_sid, in_alarm_id, in_data_dtm, OUT v_raise;
	
	IF v_raise <> 0 THEN	 	
	 	-- If the "Meter alarms" role is present then add users 
	 	-- in that role for this region to the issue
	 	v_create := TRUE;
	 	BEGiN
		 	-- Add users in that role for this region
		 	FOR r IN (
		 		SELECT rrm.user_sid
		 		  FROM region_role_member rrm
		 		  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid
		 		 WHERE rrm.region_sid = in_region_sid
		 		   AND LOWER(r.name) IN ('meter alarms', 'meter administrator')
		 	) LOOP
		 		IF v_create THEN
		 			AddIssue(in_region_sid, in_alarm_id, v_meter_alarm_name, in_data_dtm, r.user_sid, v_issue_id);
		 			v_create := FALSE;
		 		ELSE
		 			issue_pkg.AddUser(security_pkg.GetACT, v_issue_id, r.user_sid, v_out_cur);
		 		END IF;
		 	END LOOP;
	 	EXCEPTION
	 		WHEN NO_DATA_FOUND THEN
	 			NULL;
	 	END;
	 	
	 	-- If we still need to create the issue then no role or no user could be found for the given region/role
	 	IF v_create THEN
	 		AddIssue(in_region_sid, in_alarm_id, v_meter_alarm_name, in_data_dtm, NULL, v_issue_id);
	 	END IF;
	 	
	END iF;
END;

PROCEDURE IssuePeriodLastIssue (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm			IN	DATE,
	out_raise				OUT NUMBER
)
AS
	v_count					NUMBER;
	v_threshold				NUMBER;
BEGIN
	-- Fetch threshold
	SELECT issue_trigger_count
	  INTO v_threshold
	  FROM meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Fetch count since last issue
	SELECT COUNT(*)
	  INTO v_count
	  FROM meter_alarm_event
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND event_dtm <= in_test_dtm
	   AND event_dtm > (
	 	SELECT NVL(MAX(issue_dtm), TO_DATE('01-JAN-1970','DD-MON-YYYY'))
	 	  FROM issue_meter_alarm
	 	 WHERE region_sid = in_region_sid
	 	   AND meter_alarm_id = in_alarm_id
	 );
	
	-- Raise an issue?
	out_raise := 0;
	IF v_count > v_threshold THEN
	 	out_raise := 1;
	END IF;
END;

PROCEDURE IssuePeriodLastRollingMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm			IN	DATE,
	out_raise				OUT NUMBER
)
AS
	v_event_count			NUMBER;
	v_issue_count			NUMBER;
	v_threshold				NUMBER;
BEGIN
	-- Fetch threshold
	SELECT issue_trigger_count
	  INTO v_threshold
	  FROM meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Fetch event count in last rolling month	
	SELECT COUNT(*)
	  INTO v_event_count
	  FROM meter_alarm_event
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND event_dtm <= in_test_dtm
	   AND event_dtm >= ADD_MONTHS(in_test_dtm, -1);
	   
	-- Fetch related issue count in last rolling month	
	SELECT COUNT(*)
	  INTO v_issue_count
	  FROM issue_meter_alarm
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND issue_dtm <= in_test_dtm
	   AND issue_dtm >= ADD_MONTHS(in_test_dtm, -1);
	
	-- Raise an issue?
	out_raise := 0;
	IF v_event_count > v_threshold AND v_issue_count = 0 THEN
	 	out_raise := 1;
	END IF;
END;

PROCEDURE IssuePeriodLastCalendarMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm			IN	DATE,
	out_raise				OUT NUMBER
)
AS
	v_event_count			NUMBER;
	v_issue_count			NUMBER;
	v_threshold				NUMBER;
BEGIN
	-- Fetch threshold
	SELECT issue_trigger_count
	  INTO v_threshold
	  FROM meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Fetch event count in last calendar month
	SELECT COUNT(*)
	  INTO v_event_count
	  FROM meter_alarm_event
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND event_dtm <= in_test_dtm
	   AND event_dtm >= TRUNC(in_test_dtm, 'MONTH');
	
	-- Fetch related issue count in last calendar month	
	SELECT COUNT(*)
	  INTO v_issue_count
	  FROM issue_meter_alarm
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND issue_dtm <= in_test_dtm
	   AND issue_dtm >= TRUNC(in_test_dtm, 'MONTH');
	
	-- Raise an issue?
	out_raise := 0;
	IF v_event_count > v_threshold AND v_issue_count = 0 THEN
	 	out_raise := 1;
	END IF;
END;

PROCEDURE IssuePeriodLastRollingQuarter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm			IN	DATE,
	out_raise				OUT NUMBER
)
AS
	v_event_count			NUMBER;
	v_issue_count			NUMBER;
	v_threshold				NUMBER;
BEGIN
	-- Fetch threshold
	SELECT issue_trigger_count
	  INTO v_threshold
	  FROM meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Fetch count in last rolling quarter
	SELECT COUNT(*)
	  INTO v_event_count
	  FROM meter_alarm_event
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND event_dtm <= in_test_dtm
	   AND event_dtm >= ADD_MONTHS(in_test_dtm, -3);
	
	-- Fetch related issue count in last rolling quarter
	SELECT COUNT(*)
	  INTO v_issue_count
	  FROM issue_meter_alarm
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND issue_dtm <= in_test_dtm
	   AND issue_dtm >= ADD_MONTHS(in_test_dtm, -3);
	
	-- Raise an issue?
	out_raise := 0;
	IF v_event_count > v_threshold AND v_issue_count = 0 THEN
	 	out_raise := 1;
	END IF;
END;

PROCEDURE IssuePeriodLastCalendarQuarter (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_test_dtm			IN	DATE,
	out_raise				OUT NUMBER
)
AS
	v_start_month			csr.customer.start_month%TYPE;
	v_event_count			NUMBER;
	v_issue_count			NUMBER;
	v_threshold				NUMBER;
BEGIN	
	-- Get the start month
	SELECT start_month
	  INTO v_start_month
	  FROM customer;
	
	-- Fetch threshold
	SELECT issue_trigger_count
	  INTO v_threshold
	  FROM meter_alarm
	 WHERE meter_alarm_id = in_alarm_id;
	
	-- Fetch count in last calendar quarter
	SELECT COUNT(*)
	  INTO v_event_count
	  FROM meter_alarm_event
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND event_dtm <= in_test_dtm
	   AND event_dtm >= ADD_MONTHS(TRUNC(in_test_dtm, 'MONTH'),  MOD(v_start_month - 1, 3) - MOD(TO_CHAR(in_test_dtm, 'MM') - 1, 3));

	-- Fetch related issue count in last calendar quarter
	SELECT COUNT(*)
	  INTO v_issue_count
	  FROM issue_meter_alarm
	 WHERE region_sid = in_region_sid
	   AND meter_alarm_id = in_alarm_id
	   AND issue_dtm <= in_test_dtm
	   AND issue_dtm >= ADD_MONTHS(TRUNC(in_test_dtm, 'MONTH'),  MOD(v_start_month - 1, 3) - MOD(TO_CHAR(in_test_dtm, 'MM') - 1, 3));

	-- Raise an issue?
	out_raise := 0;
	IF v_event_count > v_threshold AND v_issue_count = 0 THEN
	 	out_raise := 1;
	END IF;
END;

PROCEDURE TestEveryDay (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_statistic_id			IN	meter_alarm_statistic.statistic_id%TYPE,
	in_test_dtm				IN	DATE,
	out_do_test				OUT	NUMBER
)
AS
	v_last_dtm				DATE;
BEGIN
	BEGIN
		SELECT MAX(statistic_dtm)
		  INTO v_last_dtm		
		  FROM meter_alarm_stat_run
		 WHERE meter_alarm_id = in_alarm_id
		   AND region_sid = in_region_sid
		   AND statistic_id = in_statistic_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_last_dtm := NULL;
	END;
	
	out_do_test := 0;
	-- Test at least once a day
	IF v_last_dtm IS NULL OR
	   TRUNC(in_test_dtm, 'DD') - TRUNC(v_last_dtm, 'DD') >= 1 THEN
		out_do_test := 1;
	END IF;
END;

PROCEDURE TestFirstDayOfMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_statistic_id			IN	meter_alarm_statistic.statistic_id%TYPE,
	in_test_dtm				IN	DATE,
	out_do_test				OUT	NUMBER
)
AS
	v_last_dtm				DATE;
BEGIN
	BEGIN
		SELECT MAX(statistic_dtm)
		  INTO v_last_dtm
		  FROM meter_alarm_stat_run
		 WHERE meter_alarm_id = in_alarm_id
		   AND region_sid = in_region_sid
		   AND statistic_id = in_statistic_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_last_dtm := NULL;
	END;
	
	out_do_test := 0;  
	-- Test on the first day of the month
	IF v_last_dtm IS NULL OR TO_CHAR(in_test_dtm, 'DD') = 1 THEN
		out_do_test := 1;
	END IF;
END;

PROCEDURE TestLastDayOfMonth (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_statistic_id			IN	meter_alarm_statistic.statistic_id%TYPE,
	in_test_dtm				IN	DATE,
	out_do_test				OUT	NUMBER
)
AS
	v_last_dtm				DATE;
BEGIN
	BEGIN
		SELECT MAX(statistic_dtm)
		  INTO v_last_dtm
		  FROM meter_alarm_stat_run
		 WHERE meter_alarm_id = in_alarm_id
		   AND region_sid = in_region_sid
		   AND statistic_id = in_statistic_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_last_dtm := NULL;
	END;
	
	out_do_test := 0;  
	-- Test on the last day of the month
	IF v_last_dtm IS NULL OR TO_CHAR(in_test_dtm, 'DD') = TO_CHAR(LAST_DAY(in_test_dtm), 'DD') THEN
		out_do_test := 1;
	END IF;
END;

PROCEDURE AddIssue (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_alarm_id				IN	meter_alarm.meter_alarm_id%TYPE,
	in_label				IN  issue.label%TYPE,
	in_issue_dtm			IN	issue_meter.issue_dtm%TYPE,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_issue_id			OUT issue.issue_id%TYPE
)
AS
	v_issue_user_sid		security_pkg.T_SID_ID;
	v_issue_log_id			issue_log.issue_log_id%TYPE;
	v_label					VARCHAR2(1024);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write region with sid ' || in_region_sid);
	END IF;
	
	v_issue_user_sid := meter_monitor_pkg.GetIssueUserFromRegion(in_region_sid, in_issue_dtm);
	
	-- Augment the issue label with country, propery and meter name
	v_label := in_label || ' - ' || INTERNAL_GetIssueMeterLabel(in_region_sid);

	issue_pkg.CreateIssue(
		in_label => v_label,
		in_source_label => 'Meter alarm',
		in_issue_type_id => csr_data_pkg.ISSUE_METER_ALARM, 
		in_raised_by_user_sid => v_issue_user_sid,
		in_assigned_to_user_sid => NVL(in_user_sid, v_issue_user_sid),
		in_due_dtm => NULL,
		in_region_sid => in_region_sid,
		out_issue_id => out_issue_id
	);

	INSERT INTO issue_meter_alarm (
		app_sid, issue_meter_alarm_id, region_sid, meter_alarm_id, issue_dtm)
	VALUES (
		security_pkg.GetAPP, issue_meter_alarm_id_seq.NEXTVAL, in_region_sid, in_alarm_id, in_issue_dtm
	);

	UPDATE csr.issue
	   SET issue_meter_alarm_id = issue_meter_alarm_id_seq.CURRVAL
	 WHERE issue_id = out_issue_id;
	 
	-- No alert mail will be sent just because we create a new issue, we have to 
	-- actually add a log entry to that isssue befor the mail will be generated.
	issue_pkg.AddLogEntry(security_pkg.GetACT, out_issue_id, 0, 
		'Generated new issue '''||v_label||'''', null, null, null, v_issue_log_id);
END;

PROCEDURE GetIssue(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_issue_id				IN	issue.issue_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.resolved_dtm, i.manual_completion_dtm, ima.meter_alarm_id, ima.issue_dtm,
			   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved
		  FROM issue i, issue_meter_alarm ima
		 WHERE i.app_sid = ima.app_sid
		   AND i.issue_id = in_issue_id
		   AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
		   AND ima.region_sid = in_region_sid;
END;

FUNCTION GetAlarmUrl(
	in_issue_meter_alarm_id	IN	issue_meter_alarm.issue_meter_alarm_id%TYPE
) RETURN VARCHAR2
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT app_sid, region_sid
		  INTO v_app_sid, v_region_sid
		  FROM issue_meter_alarm
		 WHERE issue_meter_alarm_id = in_issue_meter_alarm_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	RETURN meter_pkg.GetMeterPageUrl(v_app_sid)||'?meterSid='||v_region_sid;
END;

PROCEDURE GetAlarmEvents(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT e.region_sid, e.meter_alarm_id, e.meter_alarm_event_id, e.event_dtm, a.name alarm_name
		  FROM meter_alarm_event e, meter_alarm a
		 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.meter_alarm_id = e.meter_alarm_id
		   AND e.region_sid IN (
		   		SELECT NVL(link_to_region_sid, region_sid) region_sid
		   		  FROM region
		   		  	START WITH region_sid = in_region_sid
		   		  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		 );
END;

PROCEDURE PrepCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied reading region sid ' || in_region_sid);
	END IF;

	DELETE FROM temp_core_working_hours;
	INSERT INTO temp_core_working_hours (inherited_from_region_sid, core_working_hours_id, day, start_time, end_time)
		SELECT x.region_sid inherited_from_region_sid, cwh.core_working_hours_id, cwhd.day, cwh.start_time, cwh.end_time
		FROM (
			SELECT r.region_sid, hr.core_working_hours_id,
				LEVEL lvl, MIN(DECODE(hr.core_working_hours_id, NULL, NULL, LEVEL)) OVER () min_lvl
			  FROM region r
			  LEFT JOIN core_working_hours_region hr ON hr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND hr.region_sid = r.region_sid
			  WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 START WITH r.region_sid = in_region_sid
			 CONNECT BY PRIOR r.parent_sid = NVL(r.link_to_region_sid, r.region_sid)
		) x
		  JOIN core_working_hours cwh ON cwh.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND cwh.core_working_hours_id = x.core_working_hours_id
		  JOIN core_working_hours_day cwhd ON cwhd.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND cwhd.core_working_hours_id = x.core_working_hours_id
		 WHERE x.lvl = x.min_lvl
		 ORDER BY cwh.core_working_hours_id, cwhd.day, cwh.start_time, cwh.end_time
		;
END;

PROCEDURE GetCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	PrepCoreWorkingHours(in_region_sid);

	-- Mangle the output into a more UI friendly form
	OPEN out_cur FOR
		SELECT inherited_from_region_sid, inherited_from_region_desc, core_working_hours_id, 
				start_time, end_time, mon, tue, wed, thu, fri, sat, sun
		  FROM (
			SELECT x.inherited_from_region_sid, r.description inherited_from_region_desc, x.core_working_hours_id, x.start_time, x.end_time,
				MAX(x.mon) mon, MAX(x.tue) tue, MAX(x.wed) wed, MAX(x.thu) thu, MAX(x.fri) fri, MAX(x.sat) sat, MAX(x.sun) sun
			  FROM (
				SELECT inherited_from_region_sid, core_working_hours_id, start_time, end_time,
					DECODE(day, 1, 1, 0) mon,
					DECODE(day, 2, 1, 0) tue,
					DECODE(day, 3, 1, 0) wed,
					DECODE(day, 4, 1, 0) thu,
					DECODE(day, 5, 1, 0) fri,
					DECODE(day, 6, 1, 0) sat,
					DECODE(day, 7, 1, 0) sun
				  FROM temp_core_working_hours
			  ) x
			   JOIN v$region r ON r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = x.inherited_from_region_sid
			  GROUP BY x.inherited_from_region_sid, r.description, x.core_working_hours_id, x.start_time, x.end_time
			)
		  ORDER BY mon desc, tue desc, wed desc, thu desc, fri desc, sat desc, sun desc, start_time;
END;

PROCEDURE INTERNAL_GetCoreWorkingHours(
	in_cwh_id				IN	core_working_hours.core_working_hours_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Mangle the output into a more UI friendly form
	OPEN out_cur FOR
		SELECT x.region_sid inherited_from_region_sid, r.description inherited_from_region_desc,  x.core_working_hours_id, x.start_time, x.end_time,
			MAX(x.mon) mon, MAX(x.tue) tue, MAX(x.wed) wed, MAX(x.thu) thu, MAX(x.fri) fri, MAX(x.sat) sat, MAX(x.sun) sun
		  FROM (
			SELECT whr.region_sid, wh.core_working_hours_id, wh.start_time, wh.end_time,
				DECODE(whd.day, 1, 1, 0) mon,
				DECODE(whd.day, 2, 1, 0) tue,
				DECODE(whd.day, 3, 1, 0) wed,
				DECODE(whd.day, 4, 1, 0) thu,
				DECODE(whd.day, 5, 1, 0) fri,
				DECODE(whd.day, 6, 1, 0) sat,
				DECODE(whd.day, 7, 1, 0) sun
			  FROM core_working_hours wh
			  JOIN core_working_hours_day whd ON whd.app_sid = wh.app_sid AND whd.core_working_hours_id = wh.core_working_hours_id
 			  JOIN core_working_hours_region whr ON whr.app_sid = wh.app_sid AND whr.core_working_hours_id = wh.core_working_hours_id
 			 WHERE wh.app_sid = SYS_CONTEXT('SECURITY', 'APP')
 			   AND wh.core_working_hours_id = in_cwh_id
		  ) x
		   JOIN v$region r ON r.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND r.region_sid = x.region_sid
		  GROUP BY x.region_sid, r.description, x.core_working_hours_id, x.start_time, x.end_time;
END;

PROCEDURE InsertCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_start_time			IN	core_working_hours.start_time%TYPE,
	in_end_time				IN	core_working_hours.end_time%TYPE,
	in_mon					IN	NUMBER,
	in_tue					IN	NUMBER,
	in_wed					IN	NUMBER,
	in_thu					IN	NUMBER,
	in_fri					IN	NUMBER,
	in_sat					IN	NUMBER,
	in_sun					IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	TYPE ARRAY_T is VARRAY(7) OF NUMBER(1);
	v_days 					ARRAY_T := ARRAY_T(in_mon, in_tue, in_wed, in_thu, in_fri, in_sat, in_sun);
	v_cwh_id				core_working_hours.core_working_hours_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied on region with sid ' || in_region_sid);
	END IF;

	INSERT INTO core_working_hours (core_working_hours_id, start_time, end_time)
	VALUES (core_working_hours_id_seq.NEXTVAL, in_start_time, in_end_time)
	RETURNING core_working_hours_id INTO v_cwh_id;

	FOR i IN 1 .. v_days.COUNT LOOP
		IF v_days(i) != 0 THEN
			INSERT INTO core_working_hours_day (core_working_hours_id, day)
			VALUES(v_cwh_id, i);
		END IF;
	END LOOP;

	INSERT INTO core_working_hours_region (core_working_hours_id, region_sid)
	VALUES (v_cwh_id, in_region_sid);

	INTERNAL_GetCoreWorkingHours(v_cwh_id, out_cur);
END;

PROCEDURE UpdateCoreWorkingHours(
	in_cwh_id				IN	core_working_hours.core_working_hours_id%TYPE,
	in_start_time			IN	core_working_hours.start_time%TYPE,
	in_end_time				IN	core_working_hours.end_time%TYPE,
	in_mon					IN	NUMBER,
	in_tue					IN	NUMBER,
	in_wed					IN	NUMBER,
	in_thu					IN	NUMBER,
	in_fri					IN	NUMBER,
	in_sat					IN	NUMBER,
	in_sun					IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	TYPE ARRAY_T is VARRAY(7) OF NUMBER(1);
	v_days 					ARRAY_T := ARRAY_T(in_mon, in_tue, in_wed, in_thu, in_fri, in_sat, in_sun);
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM core_working_hours_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND core_working_hours_id = in_cwh_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied on region with sid ' || v_region_sid);
	END IF;

	UPDATE core_working_hours
	  SET start_time = in_start_time,
	      end_time = in_end_time
	 WHERE core_working_hours_id = in_cwh_id;

	FOR i IN 1 .. v_days.COUNT LOOP
		IF v_days(i) = 0 THEN
			DELETE FROM core_working_hours_day
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND core_working_hours_id = in_cwh_id
			   AND day = i;
		ELSE
			BEGIN
				INSERT INTO core_working_hours_day (core_working_hours_id, day)
				VALUES(in_cwh_id, i);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore if already exists
			END;
		END IF;
	END LOOP;

	INTERNAL_GetCoreWorkingHours(in_cwh_id, out_cur);
END;

PROCEDURE DeleteCoreWorkingHours(
	in_cwh_id				IN	core_working_hours.core_working_hours_id%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM core_working_hours_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND core_working_hours_id = in_cwh_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied on region with sid ' || v_region_sid);
	END IF;

	DELETE FROM core_working_hours_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND core_working_hours_id = in_cwh_id;

	DELETE FROM core_working_hours_day
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND core_working_hours_id = in_cwh_id;

	DELETE FROM core_working_hours
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND core_working_hours_id = in_cwh_id;
END;

PROCEDURE GetCoreWorkingHoursBucket (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT meter_bucket_id, description, is_hours, is_minutes, duration
		  FROM meter_bucket
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND core_working_hours = 1;
END;

FUNCTION CheckAlarmCoreWorkingHours(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_meter_alarm_id		IN	meter_alarm.meter_alarm_id%TYPE
) RETURN NUMBER
AS
	v_uses_core_hours		NUMBER;
	v_core_hours_count		NUMBER;
BEGIN
	
	-- Get the core working hours set for this region
	PrepCoreWorkingHours(in_region_sid);

	-- Are there any core hours set-up for this region
	SELECT COUNT(*)
	  INTO v_core_hours_count
	  FROM temp_core_working_hours;

	-- Check to see if the alarm uses stats that require core working hours
	SELECT MAX(core_working_hours)
	  INTO v_uses_core_hours
	  FROM (
		SELECT core_working_hours
		  FROM meter_alarm a
		  JOIN meter_alarm_statistic s ON s.app_sid = a.app_sid AND s.statistic_id = look_at_statistic_id
		 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.meter_alarm_id = in_meter_alarm_id
		UNION
		SELECT core_working_hours
		  FROM meter_alarm a
		  JOIN meter_alarm_statistic s ON s.app_sid = a.app_sid AND s.statistic_id = compare_statistic_id
		 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.meter_alarm_id = in_meter_alarm_id
	  );

	IF v_uses_core_hours > 0 AND v_core_hours_count = 0 THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

END meter_alarm_pkg;
/
