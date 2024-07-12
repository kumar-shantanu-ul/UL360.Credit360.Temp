CREATE OR REPLACE PACKAGE BODY ACTIONS.aggr_dependency_pkg
IS

PROCEDURE ClearDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ClearIndDependencies(in_act_id, in_task_sid);
	ClearTaskDependencies(in_act_id, in_task_sid);
END;

PROCEDURE ClearIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM aggr_task_ind_dependency
	 WHERE task_sid = in_task_sid;
END;

PROCEDURE ClearTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM aggr_task_task_dependency
	 WHERE task_sid = in_task_sid;
END;

-- internal
PROCEDURE AddIndDependencies(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_ind_sids);
	
	INSERT INTO aggr_task_ind_dependency (task_sid, ind_sid)
		SELECT in_task_sid, s.column_value
		  FROM TABLE(v_sid_table) s
		 MINUS
		SELECT task_sid, ind_sid
		  FROM aggr_task_ind_dependency
		 WHERE task_sid = in_task_sid;
END;

-- internal
PROCEDURE AddTaskDependencies(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_task_sids);

	INSERT INTO aggr_task_task_dependency (task_sid, depends_on_task_sid)
		SELECT in_task_sid, s.column_value
		  FROM TABLE(v_sid_table) s
		 MINUS
		SELECT task_sid, depends_on_task_sid
		  FROM aggr_task_task_dependency
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE SetDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- Clear down old dependencies
	ClearDependencies(in_act_id, in_task_sid);
	
	-- Add ind dependencies
	AddIndDependencies(in_task_sid, in_ind_sids);
		
	-- Add task dependencies
	AddTaskDependencies(in_task_sid, in_task_sids);
END;

PROCEDURE SetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- Clear down old dependencies
	ClearIndDependencies(in_act_id, in_task_sid);
	
	-- Add ind dependencies
	AddIndDependencies(in_task_sid, in_ind_sids);
END;

PROCEDURE SetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_task_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	-- Clear down old dependencies
	ClearTaskDependencies(in_act_id, in_task_sid);
	
	-- Add task dependencies
	AddTaskDependencies(in_task_sid, in_task_sids);
END;

PROCEDURE AddIndDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO aggr_task_ind_dependency (task_sid, ind_sid)
		VALUES (in_task_sid, in_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE RemoveIndDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM aggr_task_ind_dependency
	 WHERE task_sid = in_task_sid
	   AND ind_sid = in_ind_sid;
END;

PROCEDURE AddTaskDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_dep_task_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO aggr_task_task_dependency (task_sid, depends_on_task_sid)
		VALUES (in_task_sid, in_dep_task_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE RemoveTaskDependency (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_dep_task_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM aggr_task_task_dependency
	 WHERE task_sid = in_task_sid
	   AND depends_on_task_sid = in_dep_task_sid;
END;

PROCEDURE GetIndDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ind_sid
		  FROM aggr_task_ind_dependency
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE GetTaskDependencies (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT depends_on_task_sid
		  FROM aggr_task_task_dependency
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE GetDependentTaskPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	task_period.start_dtm%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT project_sid
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;

	OPEN out_cur FOR
		SELECT ttd.depends_on_task_sid, tp.task_period_status_id, tp.start_dtm, tp.end_dtm, tp.region_sid,
			tps.label status_label, tps.colour status_colour, 
			r.name region_name, r.description region_description,
			DECODE(r.parent_sid, in_region_sid, 1, 0) is_child
		  FROM task_period_status tps, csr.v$region r, 
		 	(
			 	SELECT task_sid, depends_on_task_sid 
			   	  FROM task_task_dependency
			  	 UNION
			 	SELECT task_sid, depends_on_task_sid 
			   	  FROM aggr_task_task_dependency
		 	) ttd,(
			 	SELECT task_sid, task_period_status_id, start_dtm, end_dtm, region_sid
			   	  FROM task_period
			   	 WHERE project_sid = v_project_sid
			  	 UNION
			 	SELECT task_sid, task_period_status_id, start_dtm, end_dtm, region_sid
			   	  FROM aggr_task_period
			   	 WHERE project_sid = v_project_sid
			) tp
		WHERE tp.task_period_status_id = tps.task_period_status_id
		AND tp.task_sid = ttd.depends_on_task_sid
		AND ttd.task_sid = in_task_sid
		AND tp.start_dtm = in_start_dtm
		AND tp.region_sid = r.region_sid
		AND (r.region_sid = in_region_sid OR r.parent_sid = in_region_sid);
END;


PROCEDURE GetChildRegionStatusData(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_parent_region	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT project_sid
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	OPEN out_cur FOR
		SELECT r.region_sid, r.name, r.description, 
			tp.task_period_status_id, tp.start_dtm, tp.end_dtm,
			tps.label status_label, tps.colour status_colour
	      FROM task_period_status tps, csr.v$region r,
	     	(
		      	SELECT task_sid, region_sid, task_period_status_id, start_dtm, end_dtm
		      	  FROM task_period
		      	 WHERE project_sid = v_project_sid
		      	 UNION 
		      	SELECT task_sid, region_sid, task_period_status_id, start_dtm, end_dtm
		      	  FROM aggr_task_period
		      	 WHERE project_sid = v_project_sid
	      	)tp
	     WHERE r.parent_sid = in_parent_region
	       AND tp.task_sid = in_task_sid
	       AND tp.region_sid = r.region_sid
	       AND tp.start_dtm = in_start_dtm
	       AND tps.task_period_status_id = tp.task_period_status_id;
END;

END aggr_dependency_pkg;
/
