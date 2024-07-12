CREATE OR REPLACE PACKAGE BODY ACTIONS.initiative_pkg
IS

PROCEDURE INTERNAL_CheckMandatoryFields(
	in_task_sid					IN	security_pkg.T_SID_ID, 
	in_from_task_status_id		IN	task_status.task_status_id%TYPE, 
	in_to_task_status_id		IN	task_status.task_status_id%TYPE
)
AS
	v_from_draft				task_status.is_draft%TYPE;
	v_to_draft					task_status.is_draft%TYPE;
	v_count						NUMBER;
BEGIN
	SELECT f.is_draft, t.is_draft
	  INTO v_from_draft, v_to_draft
	  FROM task_status f, task_status t
	 WHERE f.task_status_id = in_from_task_status_id
	   AND t.task_status_id = in_to_task_status_id;
	   
	IF v_to_draft = 1 OR v_from_draft = 0 THEN
		-- nothing to check
		RETURN;
	END IF;
	
	-- Start with zero invalid fields
	v_count := 0;
	
	-- Tag groups
	-- select mandatory tag groups for this task's project
	SELECT GREATEST(v_count, COUNT(*))
	  INTO v_count
	  FROM (
		SELECT DISTINCT tg.tag_group_id
		  FROM task t, project_tag_group ptg, tag_group tg
		 WHERE t.task_sid = in_task_sid
		   AND ptg.project_sid = t.project_sid
		   AND tg.tag_group_id = ptg.tag_group_id
		   AND tg.mandatory = 1
		MINUS
		-- minus any groups that have tags for this task
		SELECT DISTINCT tg.tag_group_id
		  FROM task t, project_tag_group ptg, tag_group tg, task_tag tt, tag_group_member tgm
		 WHERE t.task_sid = in_task_sid
		   AND ptg.project_sid = t.project_sid
		   AND tg.tag_group_id = ptg.tag_group_id
		   AND tg.mandatory = 1
		   AND tt.task_sid = t.task_sid
		   AND tt.tag_id = tgm.tag_id
		   AND tgm.tag_group_id = tg.tag_group_id
	  );
	
	-- Metrics - Basic mandatory field (always enforced)
	SELECT GREATEST(v_count, COUNT(*))
	  INTO v_count
	  FROM task t, task_ind_template_instance inst, project_ind_template pit, ind_template it
	 WHERE t.task_sid = in_task_sid
	   AND inst.val IS NULL
	   AND inst.task_sid = t.task_sid
	   AND pit.project_sid = t.project_sid
	   AND pit.ind_template_id = inst.from_ind_template_id
	   AND pit.update_per_period = 0
	   AND pit.is_mandatory = 1
	   AND it.ind_template_id = inst.from_ind_template_id
	   AND it.calculation IS NULL
	   AND it.is_npv = 0;

	-- Metrics - Associated periodic metric is mandatory so
	-- only one of the saving or ongoing fields are required 
	-- if an instance of the periodic metric exists
	WITH templates AS (
		SELECT epit.ind_template_id epit_ind_template_id, pit.ind_template_id pit_ind_template_id, epit.saving_template_id, epit.ongoing_template_id
		  FROM task t, task_ind_template_instance inst, project_ind_template pit, ind_template it, project_ind_template epit, task_ind_template_instance einst
		 WHERE t.task_sid = in_task_sid
		   AND inst.val IS NULL
		   AND inst.task_sid = t.task_sid
		   AND pit.project_sid = t.project_sid
		   AND pit.ind_template_id = inst.from_ind_template_id
		   AND pit.update_per_period = 0
		   AND pit.is_mandatory = 0
		   AND it.ind_template_id = inst.from_ind_template_id
		   AND it.calculation IS NULL
		   AND it.is_npv = 0
		   AND einst.task_sid = t.task_sid
		   AND epit.project_sid = t.project_sid
		   AND epit.ind_template_id = einst.from_ind_template_id
		   AND epit.is_mandatory = 1
	)
	SELECT GREATEST(v_count, COUNT(*))
	  INTO v_count
	  FROM (
		SELECT epit_ind_template_id ind_template_id
		  FROM templates
		 WHERE saving_template_id = pit_ind_template_id
		INTERSECT
		SELECT epit_ind_template_id ind_template_id
		  FROM templates
		 WHERE ongoing_template_id = pit_ind_template_id
	  );

	-- Metrics - group is mandatory, only one 
	-- item in the group need have a value
	SELECT GREATEST(v_count, COUNT(*))
	  INTO v_count
	  FROM (
		SELECT DISTINCT gp.pos_group
		  FROM task t, project_ind_template pit, ind_template_group gp
		 WHERE t.task_sid = in_task_sid
		   AND pit.project_sid = t.project_sid
		   AND gp.project_sid = pit.project_sid
		   AND gp.pos_group = pit.pos_group
		   AND gp.is_group_mandatory = 1
		MINUS
		SELECT DISTINCT pit.pos_group
		  FROM task t, task_ind_template_instance inst, project_ind_template pit, ind_template it
		 WHERE t.task_sid = in_task_sid
		   AND inst.val IS NOT NULL
		   AND inst.task_sid = t.task_sid
		   AND pit.project_sid = t.project_sid
		   AND pit.ind_template_id = inst.from_ind_template_id
		   AND pit.update_per_period = 0
		   AND pit.is_mandatory = 0
		   AND it.ind_template_id = inst.from_ind_template_id
		   AND it.calculation IS NULL
		   AND it.is_npv = 0
	  );
	
	-- Did we find any fields that should be mandatory but that were not filled in
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(ERR_MANDATORY_FIELDS, 'Status changed to a non-draft status and mandatroy fileds are not complete for task with sid '||in_task_sid);
	END IF;
END;

PROCEDURE INTERNAL_RefreshMetricNames(
	in_task_sid					IN	security_pkg.T_SID_ID
)
AS
	v_name						task.name%TYPE;
BEGIN
	SELECT name
	  INTO v_name
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_sid = in_task_sid;
	   
	FOR r IN (
		SELECT i.ind_sid, i.description
		  FROM task_ind_template_instance inst, csr.v$ind i
		 WHERE inst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = inst.ind_sid
		   AND inst.task_sid = in_task_sid
	) LOOP
		IF r.description != v_name THEN
			csr.indicator_pkg.RenameIndicator(r.ind_sid, v_name);
		END IF;
	END LOOP;
END;

PROCEDURE Barclays_GenerateInitiativeRef(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_name					OUT	task.internal_ref%TYPE
)
AS
	v_project_sid				security_pkg.T_SID_ID;
	v_project_abbr				project.abbreviation%TYPE;
	v_type_abbr					tag.tag%TYPE;
	v_region_abbr				tag.tag%TYPE;
	v_next_id					project.next_id%TYPE;
	v_check						NUMBER;
BEGIN
	-- Barclays specific procedure to generate the task name
	-- This is pointed to by the customer options table
	-- (initiative_name_gen_proc column)
	BEGIN
		
		SELECT project_sid
		  INTO v_project_sid
		  FROM task
		 WHERE task_sid = in_task_sid;
		
		-- next_id is updated by task_pkg.CreateTask, we'll only update it 
		-- here if there's a clash but we do want to lock on this project row
		SELECT v_project_sid, next_id, abbreviation
		  INTO v_project_sid, v_next_id, v_project_abbr
		  FROM project
		 WHERE project_sid = v_project_sid
		 	FOR UPDATE OF next_id;
		
		BEGIN
			SELECT UPPER(SUBSTR(t.tag, 1, 1))
			  INTO v_type_abbr
			  FROM tag_group tg, tag_group_member tgm, tag t, task_tag tt
			 WHERE tg.name = 'Entry Type'
			   AND tgm.tag_group_id = tg.tag_group_id
			   AND t.tag_id = tgm.tag_id
			   AND tt.tag_id = t.tag_id
			   AND tt.task_sid = in_task_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_type_abbr := 'U';
		END;
		
		BEGIN
			SELECT UPPER(SUBSTR(t.tag, 1, 2))
			  INTO v_region_abbr
			  FROM tag_group tg, tag_group_member tgm, tag t, task_tag tt
			 WHERE tg.name = 'Region'
			   AND tgm.tag_group_id = tg.tag_group_id
			   AND t.tag_id = tgm.tag_id
			   AND tt.tag_id = t.tag_id
			   AND tt.task_sid = in_task_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_region_abbr := 'UU';
		END;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_name := '#ERROR#';
			RETURN;
	END;
	
	LOOP
		-- Format the name
		out_name := v_project_abbr ||'-'|| v_type_abbr ||'-'|| v_region_abbr ||'-'|| v_next_id;
	
		-- Check for uniqueness (just in case someone 
		-- happened to import a task with this reference)
		SELECT COUNT(*)
		  INTO v_check
		  FROM task
		 WHERE internal_ref = out_name;
		
		EXIT WHEN v_check = 0;
		
		-- If we get here then a dupe was found, 
		-- update the next_id and try again
		v_next_id := v_next_id + 1;
		UPDATE project
		   SET next_id = v_next_id
		 WHERE project_sid = v_project_sid;
	END LOOP;
END;

PROCEDURE RBSENV_GenerateInitiativeName(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_name					OUT	task.internal_ref%TYPE
)
AS
	v_project_sid				security_pkg.T_SID_ID;
	v_region_sid				security_pkg.T_SID_ID;
	v_project_abbr				project.abbreviation%TYPE;
	v_country_abbr				VARCHAR2(3);
BEGIN
	-- RBSENV specific procedure to generate the task name
	-- This is pointed to by the customer options table
	-- (initiative_name_gen_proc column)
	BEGIN
		SELECT t.project_sid, tr.region_sid
		  INTO v_project_sid, v_region_sid
		  FROM task t, task_region tr
		 WHERE t.task_sid = in_task_sid
		   AND tr.task_sid = t.task_sid
		   AND ROWNUM = 1;

		SELECT UPPER(abbreviation)
		  INTO v_project_abbr
		  FROM project
		 WHERE project_sid = v_project_sid;

		 SELECT UPPER(SUBSTR(r.description, 1, 3))
		   INTO v_country_abbr
		   FROM (
			SELECT LEVEL lvl, region_sid, name, description, MAX(LEVEL) over () max_lvl
		  	  FROM csr.v$region
				START WITH region_sid = v_region_sid
				CONNECT BY PRIOR  parent_sid = region_sid
			) r
		 WHERE r.max_lvl - r.lvl = 3;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_name := NULL;
			RETURN;
	END;

	-- Format the name
	out_name := v_project_abbr || v_country_abbr || in_task_sid;
END;

PROCEDURE GetBaseRegions(
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_user_root_count		NUMBER;
	v_region_root 			security_pkg.T_SID_ID;
BEGIN
	-- TODO: this is very specific to rbsenv
	-- need to find a nice way of finding the base set of regions

	SELECT region_tree_root_sid
	  INTO v_region_root
	  FROM csr.region_tree
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND is_primary = 1;

	SELECT COUNT(*)
	  INTO v_user_root_count
	  FROM csr.region_start_point
	 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND region_sid != v_region_root;

	-- If the user has region mount points that aren't the primary tree root then use those
	IF v_user_root_count > 0 THEN
		OPEN out_cur FOR
			SELECT r.region_sid, r.name, r.description
			  FROM csr.v$region r, csr.region_start_point rsp
			 WHERE rsp.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND r.app_sid = rsp.app_sid AND r.region_sid = rsp.region_sid
			   AND rsp.region_sid != v_region_root;
		RETURN;
	END IF;

	-- Otherwise do something totally RBS specific
	OPEN out_cur FOR
		SELECT r.region_sid, r.name, r.description
		  FROM (
			SELECT LEVEL lvl, region_sid, name, description
			  FROM csr.v$region
				START WITH parent_sid = v_region_root
					   AND LOWER(name) = 'rbs_group'
				CONNECT BY PRIOR region_sid = parent_sid
		) r
		 WHERE r.lvl = 2
		 ORDER BY LOWER(r.description);
END;

PROCEDURE GetTypesForProject(
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ptg.project_sid, t.tag_id, t.tag
		  FROM project_tag_group ptg, tag_group tg, tag_group_member tgm, tag t
		 WHERE ptg.project_sid = in_project_sid
		   AND ptg.tag_group_id = tg.tag_group_id
		   AND tg.name = 'initiative_sub_type'
		   AND tgm.tag_group_id = tg.tag_group_id
		   AND t.tag_id = tgm.tag_id;
END;

PROCEDURE GetCountryList(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.name, r.description
		  FROM (
			SELECT LEVEL lvl, region_sid, name, description
			  FROM csr.v$region
				START WITH region_sid = in_region_sid
				CONNECT BY PRIOR region_sid = parent_sid
		) r
		 WHERE r.lvl = 2;
END;

PROCEDURE GetPropertyList(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_query				IN	VARCHAR2,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.name, r.description
		  FROM (
		  	SELECT CONNECT_BY_ISLEAF isleaf, region_sid, name, description
		  	  FROM csr.v$region
		  	 WHERE LOWER(description) LIKE '%' || LOWER(in_query) || '%'
			  	START WITH region_sid = in_region_sid
			  	CONNECT BY PRIOR region_sid = parent_sid
		) r
		 WHERE r.isleaf <> 0;
END;

PROCEDURE GetSelectedRegions(
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.region_sid, r.description region_desc
		  FROM task_region tr, csr.v$region r
		 WHERE tr.task_sid = in_task_sid
		   AND r.region_sid = tr.region_sid;
END;

PROCEDURE GetSelectedProperties(
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_region_level			customer_options.region_level%TYPE;
   	v_country_level			customer_options.country_level%TYPE;
   	v_property_level		customer_options.property_level%TYPE;
BEGIN
	-- Clear temp table
	DELETE FROM initiative_properties;

	-- Get levels
	SELECT region_level, country_level, property_level
	  INTO v_region_level, v_country_level, v_property_level
	  FROM customer_options
	 WHERE app_sid = security_pkg.GetAPP;

	FOR r IN (
		SELECT tr.region_sid
		  FROM task_region tr, csr.region r
		 WHERE tr.task_sid = in_task_sid
		   AND r.region_sid = tr.region_sid
	) LOOP
		INSERT INTO initiative_properties (
		  SELECT region_sid, region_desc,
		  		 NVL(country_sid, region_sid), NVL(country_desc, region_desc),
		  		 DECODE(country_sid, NULL, NULL, prop_sid), DECODE(country_sid, NULL, NULL, prop_desc)
			 FROM (
				SELECT
				    MAX(DECODE(lvl, v_region_level, region_sid, NULL)) region_sid, MAX(DECODE(lvl, v_region_level, description, NULL)) region_desc,
				    MAX(DECODE(lvl, v_country_level, region_sid, NULL)) country_sid, MAX(DECODE(lvl, v_country_level, description, NULL)) country_desc,
				    MAX(DECODE(lvl, v_property_level, NULL, DECODE(lvl, max_lvl, region_sid, NULL))) prop_sid, MAX(DECODE(lvl, v_property_level, NULL, DECODE(lvl, max_lvl, description, NULL))) prop_desc
				  FROM (
				    SELECT
				    	MAX(level) over () - 1 max_lvl,
				    	MAX(level) over () - level lvl,
				    	rgn.region_sid, rgn.description
				     FROM csr.v$region rgn
				    	START WITH rgn.region_sid = r.region_sid
				    	CONNECT BY PRIOR rgn.parent_sid = rgn.region_sid
				)
			)
		);
	END LOOP;

	OPEN out_cur FOR
		SELECT region_sid, region_desc,
			country_sid, country_desc,
			property_sid, property_desc
		  FROM initiative_properties
		 ORDER BY region_desc, country_desc, property_desc;
END;

PROCEDURE GetInitiativeDetails(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_details					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_details FOR
		SELECT t.task_sid, t.parent_task_sid, t.name task_name, t.internal_ref task_reference,
			t.start_dtm, t.end_dtm, t.period_duration, t.fields_xml, t.output_ind_sid,
			p.project_sid, p.name project_name, ts.is_live, ts.is_rejected, ts.is_stopped,
			TRUNC(SYSDATE, 'MONTH') current_month
		  FROM task t, project p, task_status ts
		 WHERE t.task_sid = in_task_sid
		   AND p.project_sid = t.project_sid
		   AND ts.task_status_id = t.task_status_id;
END;

PROCEDURE BulkGetInitiativeDetails(
	in_task_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_sid_table					security.T_SID_TABLE;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_task_sids);

	OPEN out_cur FOR
		SELECT t.task_sid, t.name task_name, t.internal_ref task_reference,
			t.start_dtm, t.end_dtm, t.period_duration, t.fields_xml, t.output_ind_sid,
			p.project_sid, p.name project_name, ts.is_live, ts.is_rejected, ts.is_stopped,
			TRUNC(SYSDATE, 'MONTH') current_month
		  FROM task t, project p, task_status ts, TABLE(v_sid_table) sids
		 WHERE t.task_sid = sids.COLUMN_VALUE
		   AND p.project_sid = t.project_sid
		   AND ts.task_status_id = t.task_status_id;
END;

PROCEDURE GetInitiativeOverview(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_details					OUT	SYS_REFCURSOR,
	out_properties				OUT	SYS_REFCURSOR,
	out_tags					OUT	SYS_REFCURSOR
)
AS
	v_standard_picker			customer_options.use_standard_region_picker%TYPE;
BEGIN
	-- Get some task details
	GetInitiativeDetails(in_task_sid, out_details);

	-- Get some tag information
	OPEN out_tags FOR
		SELECT tg.tag_group_id, tg.name, t.tag_id, t.tag
		  FROM task_tag tt, tag t, tag_group_member tgm, tag_group tg
		 WHERE tt.task_sid = in_task_sid
		   AND t.tag_id = tt.tag_id
		   AND tgm.tag_id = t.tag_id
		   AND tg.tag_group_id = tgm.tag_group_id;

	-- Read customer options for region picker type
	SELECT use_standard_region_picker
	  INTO v_standard_picker
	  FROM customer_options
	 WHERE app_sid = security_pkg.GetAPP;

	-- Get selected region/properties
	IF v_standard_picker <> 0 THEN
		GetSelectedRegions(in_task_sid, out_properties);
	ELSE
		GetSelectedProperties(in_task_sid, out_properties);
	END IF;
END;

PROCEDURE DeleteInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID
)
AS
	v_count						NUMBER;
BEGIN
	-- Validate the passed SID is a task, if so
	-- then just hand over the job to security
	SELECT COUNT(*)
	  INTO v_count
	  FROM task
	 WHERE task_sid = in_task_sid;

	IF v_count > 0 THEN
		securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_task_sid);
	END IF;
END;

PROCEDURE AutoGenerateRef(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_name					OUT	task.name%TYPE
)
AS
	v_gen_name_proc				customer_options.initiative_name_gen_proc%TYPE;
BEGIN
	SELECT initiative_name_gen_proc
	  INTO v_gen_name_proc
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- NOTE: this actually generates the
	-- internal reference, NOT THE NAME
	IF LENGTH(v_gen_name_proc) > 0 THEN
		EXECUTE IMMEDIATE 'begin '||v_gen_name_proc||'(:1,:2);end;'
			USING IN in_task_sid, OUT out_name;
		UPDATE task
		   SET internal_ref = out_name
		 WHERE task_sid = in_task_sid;
	END IF;
END;

PROCEDURE INTERNAL_GetParentDates(
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid			IN	security_pkg.T_SID_ID,
	out_start_dtm				OUT	task.start_dtm%TYPE,
	out_end_dtm					OUT	task.end_dtm%TYPE
)
AS
BEGIN
	-- Read project/parent dates
	IF in_parent_task_sid IS NOT NULL THEN
		SELECT start_dtm, end_dtm
		  INTO out_start_dtm, out_end_dtm
		  FROM task t
		 WHERE t.task_sid = in_parent_task_sid;
	ELSE
		SELECT start_dtm, end_dtm
		  INTO out_start_dtm, out_end_dtm
		  FROM project p
		 WHERE p.project_sid = in_project_sid;
	END IF;
END;

PROCEDURE INTERNAL_GetParentDates(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_start_dtm				OUT	task.start_dtm%TYPE,
	out_end_dtm					OUT	task.end_dtm%TYPE
)
AS
BEGIN
	-- Read project/parent dates
	SELECT NVL(pt.start_dtm, pr.start_dtm), NVL(pt.end_dtm, pr.end_dtm)
	  INTO out_start_dtm, out_end_dtm
	  FROM task ct, task pt, project pr
	 WHERE ct.task_sid = in_task_sid
	   AND pt.task_sid(+) = ct.parent_task_sid
	   AND pr.project_sid = ct.project_sid;
END;

-- This version of CreateInitiative is used by the create page, 
-- it has a limited set of arguments as we're not interested in 
-- capturing many of the attributetes we can associate with an 
-- initiative/action.
PROCEDURE CreateInitiative(
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	in_task_status_id			IN	task_status.task_status_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	CreateInitiative(
		in_name,
		in_ref,
		in_project_sid,
		in_parent_task_sid,
		in_task_status_id,	-- Task status id (if null will be computed for us)
		in_tags,
		in_fields_xml,
		in_prop_sids,		-- Regions
		in_start_dtm,
		in_end_dtm,
		NULL,				-- period duration (if null will be comuted for us)
		NULL,				-- budget
		NULL,				-- short name
		NULL,				-- input ind sid
		NULL,				-- target ind sid
		1.0,				-- weighting
		'M',				-- action type (Management)
		'R',				-- entry type (Radio buttons)
		in_one_off,
		NULL,				-- Owner sid (NULL == logged on user)
		NULL,				-- Created dtm (NULL == current dtm)
		in_project_team_names,
		in_project_team_emails,
		in_sponsor_names,
		in_sponsor_emails,
		in_periodic_ids,
		in_static_ids,
		in_static_vals,
		in_static_uoms,
		out_cur
	);
END;

-- This version of CreateInitiative is called from the importer,
-- as the importer can be used to capture initiatives or just plain 
-- old actions we are provide an interface that allows us to set any 
-- of the attributes associated with an action or an initiative, 
-- after all an initiative is just an action with some extra metric 
-- data associated with it.
PROCEDURE CreateInitiative(
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_task_status_id			IN	task_status.task_status_id%TYPE,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_period_duration	        IN	TASK.period_duration%TYPE,
	in_budget					IN	TASK.budget%TYPE,
	in_short_name				IN	TASK.short_name%TYPE,
	in_input_ind_sid			IN	security_pkg.T_SID_ID,
	in_target_ind_sid			IN	security_pkg.T_SID_ID,
	in_weighting				IN	TASK.weighting%TYPE,
	in_action_type				IN	TASK.action_type%TYPE,
	in_entry_type				IN	TASK.entry_type%TYPE,
	in_one_off					IN	NUMBER,
	in_owner_sid				IN	security_pkg.T_SID_ID,
	in_created_dtm				IN	task.created_dtm%TYPE,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_project_start_dtm			project.start_dtm%TYPE;
	v_project_end_dtm			project.end_dtm%TYPE;
	v_period_duration	        TASK.period_duration%TYPE;
	v_task_status_id			task_status.task_status_id%TYPE;
	v_sid_table 				security.T_SID_TABLE;
	v_tag_table 				security.T_SID_TABLE;
	v_name						task.name%TYPE;
	v_ref						task.internal_ref%TYPE;
	v_task_sid					security_pkg.T_SID_ID;
	c_task_info					SYS_REFCURSOR;
	v_task_info					task_pkg.REC_SIMPLE_TASK_INFO;
	v_start_dtm					task.start_dtm%TYPE;
	v_end_dtm					task.end_dtm%TYPE;
BEGIN
	INTERNAL_GetParentDates(
		in_project_sid, in_parent_task_sid,
		v_project_start_dtm, v_project_end_dtm
	);

	-- Get task status and period duration to use
	SELECT NVL(in_task_status_id, t.task_status_id), NVL(in_period_duration, max_period_duration),
		NVL(in_start_dtm, p.start_dtm), NVL(in_end_dtm, p.end_dtm)
	  INTO v_task_status_id, v_period_duration, v_start_dtm, v_end_dtm
	  FROM task_status t, project_task_status pts, project p
	 WHERE p.project_sid = in_project_sid
	   AND pts.project_sid = p.project_sid
	   AND t.task_status_id = pts.task_status_id
	   AND t.is_default = 1;

	-- Create the task
	task_pkg.CreateTask(
	 	in_project_sid,
	 	in_parent_task_sid,
	 	v_task_status_id,
	 	in_name,
	 	v_project_start_dtm,
	 	v_project_end_dtm,
	 	v_period_duration,
	 	in_fields_xml,
	 	0,					-- is container
	 	in_ref,				-- internal ref
	 	in_budget,			-- budget
	 	in_short_name,		-- short name
	 	in_input_ind_sid,	-- input ind sid
	 	in_target_ind_sid,	-- target ind sid
	 	in_weighting,		-- weighting
	 	in_action_type,		-- action type (management)
	 	in_entry_type,		-- entry type (radio buttons)
	 	c_task_info			-- created task info
	);
	
	-- Extract the task sid from the output cursor
	FETCH c_task_info INTO v_task_info;
	v_task_sid := v_task_info.task_sid;
	CLOSE c_task_info;

	-- Update owner if required
	IF in_owner_sid IS NOT NULL THEN
		UPDATE task
		   SET owner_sid = in_owner_sid
		 WHERE task_sid = v_task_sid;
	END IF;
	
	-- Set the created dtm if required
	IF in_created_dtm IS NOT NULL THEN
		UPDATE task
		  SET created_dtm = in_created_dtm
		WHERE task_sid = v_task_sid;
	END IF;

	-- Type ids (task tag ids)
	v_tag_table := security_pkg.SidArrayToTable(in_tags);
	INSERT INTO task_tag (task_sid, tag_id)
		SELECT v_task_sid, t.column_value
		  FROM TABLE(v_tag_table) t;

	-- Process regions (properties)
	v_sid_table := security_pkg.SidArrayToTable(in_prop_sids);
	INSERT INTO task_region (task_sid, region_sid)
		SELECT v_task_sid, t.column_value
		  FROM TABLE(v_sid_table) t
		MINUS 
		SELECT task_sid, region_sid
		  FROM task_region
		 WHERE task_sid = v_task_sid;

	-- Create a set of metrics based on the contents of project_ind_template
	-- The user can select the update_per_period metrics so only create
	-- those metrics where update_per_period at this stage.
	FOR r IN (
		SELECT pit.ind_template_id
		  FROM ind_template it, project_ind_template pit
		 WHERE it.ind_template_id = pit.ind_template_id
		   AND it.calculation IS NULL -- We'll create the calculation indicators later
		   AND it.is_npv = 0 -- We'll create any npv indicators later (after calculations)
		   AND pit.project_sid = in_project_sid
		   AND pit.update_per_period = 0
	) LOOP
		ind_template_pkg.CreateMetric(v_task_sid, r.ind_template_id);
	END LOOP;

	-- Create the rest of the initiative (this data used to be on a separate page
	-- (and the code in SetInitiativeImpl is generic to both create and amend)
	SetInitiativeImpl(
		v_task_sid,
		v_start_dtm,
		v_end_dtm,
		in_one_off,
		in_project_team_names,
		in_project_team_emails,
		in_sponsor_names,
		in_sponsor_emails,
		in_periodic_ids,
		in_static_ids,
		in_static_vals,
		in_static_uoms
	);

	-- If the caller passes in a reference that is not null then use that instead
	IF in_ref IS NULL THEN
		-- Right now the initiative is created we might
		-- want to generate a new reference using a helper procedure
		-- AutoGenerateRef will not modify the reference if no
		-- helper is specified in customer options
		AutoGenerateRef(v_task_sid, v_ref);
	END IF;
	
	-- Data cubes will need recomputing
	scenario_pkg.OnTaskStatusChanged(v_task_sid, NULL, v_task_status_id);

	OPEN out_cur FOR
		SELECT task_sid, name, internal_ref reference
		  FROM task
		 WHERE task_sid = v_task_sid;
END;

-- As for CreateInitiative, this version of AmendInitiative has cut-down arguments 
-- and is called from the create page (See notes for CreateInitiative procedure)
PROCEDURE AmendInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_tags_valid				IN	NUMBER,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_valid				IN	NUMBER,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_valid		IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_valid			IN	NUMBER,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_valid			IN	NUMBER,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_valid				IN	NUMBER,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	AmendInitiative(
		in_task_sid,
		in_name,
		in_ref,
		in_project_sid,
		in_parent_task_sid,
		NULL,
		in_tags_valid,
		in_tags,
		in_fields_xml,
		in_prop_valid,
		in_prop_sids,
		in_start_dtm,
		in_end_dtm,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		1.0,
		'M',
		'R',
		in_one_off,
		NULL,
		NULL,
		in_project_team_valid,
		in_project_team_names,
		in_project_team_emails,
		in_sponsor_valid,
		in_sponsor_names,
		in_sponsor_emails,
		in_periodic_valid,
		in_periodic_ids,
		in_static_valid,
		in_static_ids,
		in_static_vals,
		in_static_uoms,
		out_cur
	);
END;

-- As for CreateInitiative, this version of AmendInitiative is able to amend 
-- all the attributes of an initiative/action, this is called from the importer 
-- (See notes for CreateInitiative procedure).
PROCEDURE AmendInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	task.name%TYPE,
	in_ref						IN	task.internal_ref%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_task_status_id			IN	task_status.task_status_id%TYPE,
	in_tags_valid				IN	NUMBER,
	in_tags						IN	security_pkg.T_SID_IDS,
	in_fields_xml				IN	task.fields_xml%TYPE,
	in_prop_valid				IN	NUMBER,
	in_prop_sids				IN	security_pkg.T_SID_IDS,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_period_duration	        IN	TASK.period_duration%TYPE,
	in_budget					IN	TASK.budget%TYPE,
	in_short_name				IN	TASK.short_name%TYPE,
	in_input_ind_sid			IN	security_pkg.T_SID_ID,
	in_target_ind_sid			IN	security_pkg.T_SID_ID,
	in_weighting				IN	TASK.weighting%TYPE,
	in_action_type				IN	TASK.action_type%TYPE,
	in_entry_type				IN	TASK.entry_type%TYPE,
	in_one_off					IN	NUMBER,
	in_owner_sid				IN	security_pkg.T_SID_ID,
	in_created_dtm				IN	task.created_dtm%TYPE,
	in_project_team_valid		IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_valid			IN	NUMBER,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_valid			IN	NUMBER,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_valid				IN	NUMBER,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_project_sid				security_pkg.T_SID_ID;
	v_project_start_dtm			project.start_dtm%TYPE;
	v_project_end_dtm			project.end_dtm%TYPE;
	v_task_status_id			task_status.task_status_id%TYPE;
	v_sid_table 				security.T_SID_TABLE;
	v_val_id					csr.val.val_id%TYPE;
	v_regions_changed			NUMBER;
	v_old_region_count			NUMBER(10);
	v_new_region_count			NUMBER(10);
	v_tag_table 				security.T_SID_TABLE;
	v_old_name					task.name%TYPE;
	v_new_name					task.name%TYPE;
	v_ref						task.internal_ref%TYPE;
	v_task_status				task.task_status_id%TYPE;
	v_old_task_status_id		task.task_status_id%TYPE;
	v_start_dtm					task.start_dtm%TYPE;
	v_end_dtm					task.end_dtm%TYPE;
	v_old_parent_sid			security_pkg.T_SID_ID;
	v_update_ref_on_amend		NUMBER(1) := 0;
BEGIN
	-- If the project changed then we need to delete
	-- the task and start again (indicator tree etc.)
	SELECT project_sid
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;

	-- we need to specify the current task status when we re-create the initiative
	SELECT task_status_id, NVL(in_start_dtm, start_dtm), NVL(in_end_dtm, end_dtm)
	  INTO v_task_status, v_start_dtm, v_end_dtm
	  FROM task
	 WHERE task_sid = in_task_sid;

	IF in_project_sid != v_project_sid THEN
		securableobject_pkg.DeleteSO(security_pkg.GetAct, in_task_sid);
		-- XXX: Use longer form of CreateInitiative!!!
		CreateInitiative(
			in_name,
			in_ref,
			in_project_sid,
			in_parent_task_sid,
			in_tags,
			in_fields_xml,
			in_prop_sids,
			v_start_dtm,
			v_end_dtm,
			in_one_off,
			in_project_team_names,
			in_project_team_emails,
			in_sponsor_names,
			in_sponsor_emails,
			in_periodic_ids,
			in_static_ids,
			in_static_vals,
			in_static_uoms,
			v_task_status,
			out_cur
		);
		RETURN;
	END IF;
	
	-- Get the current name
	SELECT name
	  INTO v_old_name
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_sid = in_task_sid;

	-- Update the parent task sid if required
	IF in_parent_task_sid IS NOT NULL THEN
		-- Fetch the current (old) parent
		SELECT parent_task_sid
		  INTO v_old_parent_sid
		  FROM task
		 WHERE task_sid = in_task_sid;
		-- If the parent changed move the object (this will call the hook in task_pkg)
		IF in_parent_task_sid <> v_old_parent_sid THEN
			-- Null out the name, AmendTask will deal with name conflicts
			securableobject_pkg.RenameSO(security_pkg.GetACT, in_task_sid, null);
			securableobject_pkg.MoveSO(security_pkg.GetACT, in_task_sid, in_parent_task_sid);
		END IF;
	END IF;
	
	-- Get current date bounds, the dates will be udpated later on in SetInitiativeImpl
	INTERNAL_GetParentDates(in_task_sid, v_project_start_dtm, v_project_end_dtm);

	 -- Change the task
	 task_pkg.AmendTask(
	 	in_task_sid,
	 	in_name,
	 	v_project_start_dtm,
	 	v_project_end_dtm,
	 	in_period_duration,
	 	in_fields_xml,
	 	0,
	 	in_ref,
	 	in_budget,
	 	in_short_name,
	 	NULL,				-- output ind sid
	 	in_input_ind_sid,
	 	in_target_ind_sid,
	 	in_weighting,
	 	in_action_type,
	 	in_entry_type
	 );

	-- Get the current name
	SELECT name
	  INTO v_new_name
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_sid = in_task_sid;
	
	-- Ensure SO name is present and correct
	utils_pkg.UniqueSORename(security_pkg.GetACT, in_task_sid, SUBSTR(Replace(v_new_name,'/','\'),0,255));
	
	-- Check for a name change
	IF v_old_name <> v_new_name THEN
		INTERNAL_RefreshMetricNames(in_task_sid);
	END IF;

	-- Set the owner if required
	IF in_owner_sid IS NOT NULL THEN
		UPDATE task
		   SET owner_sid = in_owner_sid
		 WHERE task_sid = in_task_sid;
	END IF;
	
	-- Set the created dtm if required
	IF in_created_dtm IS NOT NULL THEN
		UPDATE task
		  SET created_dtm = in_created_dtm
		WHERE task_sid = in_task_sid;
	END IF;

	-- Set task status
	IF in_task_status_id IS NOT NULL THEN
		-- Get the old task status
		SELECT task_status_id
		  INTO v_old_task_status_id
		  FROM task
		 WHERE task_sid = in_task_sid;
		-- Set the new task status
		task_pkg.SetTaskStatus(security_pkg.GetACT, in_task_sid, in_task_status_id, 'Status changed from AmendInitiative');
		-- Data cubes will need recomputing
		scenario_pkg.OnTaskStatusChanged(in_task_sid, v_old_task_status_id, in_task_status_id);
	END IF;

	-- Type ids (task tag ids)
	IF in_tags_valid <> 0 THEN
		
		v_tag_table := security_pkg.SidArrayToTable(in_tags);
		
		-- Delete anything that exists that's not in the list
		FOR r IN (
			SELECT tag_id
			  FROM task_tag
			 WHERE task_sid = in_task_sid
			MINUS 
			SELECT column_value tag_id
			  FROM TABLE(v_tag_table)
		) LOOP
			-- Delete the task/tag relationship
			DELETE FROM task_tag
			 WHERE task_sid = in_task_sid
			   AND tag_id = r.tag_id;
		END LOOP;
		
		-- Add anything in the list that is not already present
		INSERT INTO task_tag (task_sid, tag_id)
			SELECT in_task_sid, column_value tag_id
			  FROM TABLE(v_tag_table)
			MINUS
			SELECT in_task_sid, tag_id
			  FROM task_tag
			 WHERE task_sid = in_task_sid;
	END IF;
	
	-- Process regions (properties)
	IF in_prop_valid <> 0 THEN
		
		v_regions_changed := 0;
		v_sid_table := security_pkg.SidArrayToTable(in_prop_sids);
	
		-- How many regions is the task currently associated with
		SELECT COUNT(*)
		  INTO v_old_region_count
		  FROM task_region
		 WHERE task_sid = in_task_sid;
	
		-- How many regions will the task be associated with after the change
		SELECT COUNT(*)
		  INTO v_new_region_count
		  FROM TABLE(v_sid_table);
	
		-- Insert new regions
		INSERT INTO task_region (task_sid, region_sid)
			SELECT in_task_sid, r.region_sid
			  FROM (
				SELECT COLUMN_VALUE region_sid
			  	  FROM TABLE(v_sid_table)
			  	MINUS
			  	SELECT region_sid
			  	  FROM task_region
			  	 WHERE task_sid = in_task_sid
			) r;
	
		-- Copy progress data to new regions
		FOR r IN (
			SELECT region_sid
			  FROM (
				SELECT COLUMN_VALUE region_sid
			  	  FROM TABLE(v_sid_table)
			  	MINUS
			  	SELECT region_sid
			  	  FROM task_region
			  	 WHERE task_sid = in_task_sid
			) r
		) LOOP
			-- Region data has changed
			v_regions_changed := 1;
	
			-- Just use the first existing region we find as the task period
			-- data should be the same for all the regions involved
			INSERT INTO task_period (task_sid, start_dtm, region_sid, project_sid, task_period_status_id,
					end_dtm, entered_dtm, entered_by_sid, fields_xml, needs_aggregation)
				SELECT task_sid, start_dtm, r.region_sid, project_sid, task_period_status_id,
						end_dtm, SYSDATE, security_pkg.GetSID, fields_xml, 0
				  FROM task_period
				 WHERE task_sid = in_task_sid
				   AND region_sid = (
				   		SELECT region_sid
				   		  FROM task_region
				   		 WHERE task_sid = in_task_sid
				   		  AND ROWNUM = 1
				   );
	
			-- Just use the first existing region we find as the metric
			-- data should be the same for all the regions involved
			FOR v IN (
				SELECT v.ind_sid, v.period_start_dtm, v.period_end_dtm, entry_measure_conversion_id,
					(val_number * v_old_region_count) / v_new_region_count val_number,
					DECODE(entry_val_number, NULL, NULL, (entry_val_number * v_old_region_count) / v_new_region_count) entry_val_number
				  FROM csr.val v, task t
				 WHERE t.task_sid = in_task_sid
				   AND v.ind_sid = t.output_ind_sid
				   AND v.region_sid = (
			   		SELECT region_sid
			   		  FROM task_region
			   		 WHERE task_sid = in_task_sid
			   		  AND ROWNUM = 1
				   )
			) LOOP
				csr.indicator_pkg.SetValue(
					security_pkg.GetAct,
					v.ind_sid,
					r.region_sid,
					v.period_start_dtm,
					v.period_end_dtm,
					v.val_number,
					0,
					csr.csr_data_pkg.SOURCE_TYPE_DIRECT,
					NULL,
					v.entry_measure_conversion_id,
					v.entry_val_number,
					0,
					NULL,
					v_val_id
				);
			END LOOP;
		END LOOP;
	
		-- Copy metric data to new regions
		FOR r IN (
			SELECT i.ind_sid, r.region_sid
			  FROM (
				SELECT COLUMN_VALUE region_sid
			  	  FROM TABLE(v_sid_table)
			  	MINUS
			  	SELECT region_sid
			  	  FROM task_region
			  	 WHERE task_sid = in_task_sid
			) r, task_ind_template_instance i
		) LOOP
			-- Region data has changed
			v_regions_changed := 1;
	
			-- Just use the first existing region we find as the metric
			-- data should be the same for all the regions involved
			FOR v IN (
				SELECT v.period_start_dtm, v.period_end_dtm, val_number, entry_measure_conversion_id, entry_val_number
				  FROM csr.val v
				 WHERE v.ind_sid = r.ind_sid
				   AND v.region_sid = (
			   		SELECT region_sid
			   		  FROM task_region
			   		 WHERE task_sid = in_task_sid
			   		  AND ROWNUM = 1
				   )
			) LOOP
				csr.indicator_pkg.SetValue(
					security_pkg.GetAct,
					r.ind_sid,
					r.region_sid,
					v.period_start_dtm,
					v.period_end_dtm,
					v.val_number,
					0,
					csr.csr_data_pkg.SOURCE_TYPE_DIRECT,
					NULL,
					v.entry_measure_conversion_id,
					v.entry_val_number,
					0,
					NULL,
					v_val_id
				);
			END LOOP;
		END LOOP;
	
		-- Delete old regions
		FOR r IN (
			SELECT region_sid
			  FROM (
			  	SELECT region_sid
			  	  FROM task_region
			  	 WHERE task_sid = in_task_sid
			  	MINUS
			  	SELECT COLUMN_VALUE region_sid
			  	  FROM TABLE(v_sid_table)
			) r
		) LOOP
			-- Delete task period data
			DELETE FROM task_period_file_upload
			 WHERE task_sid = in_task_sid
			   AND region_sid = r.region_sid;
	
			DELETE FROM task_period_override
			 WHERE task_sid = in_task_sid
			   AND region_sid = r.region_sid;
	
			DELETE FROM task_period
			 WHERE task_sid = in_task_sid
			   AND region_sid = r.region_sid;
	
			-- Delete aggr task period data
			DELETE FROM aggr_task_period_override
			 WHERE task_sid = in_task_sid
			   AND region_sid = r.region_sid;
	
			DELETE FROM aggr_task_period
			 WHERE task_sid = in_task_sid
			   AND region_sid = r.region_sid;
	
			-- Delete task region association
			DELETE FROM task_region
			 WHERE task_sid = in_task_sid
			   AND region_sid = r.region_sid;
	
			-- Delete progress values from main system
			FOR v IN (
				SELECT val_id
				  FROM csr.val v, task t
				 WHERE t.task_sid = in_task_sid
				   AND v.ind_sid = t.output_ind_sid
				   AND v.region_sid = r.region_sid
			) LOOP
				csr.indicator_pkg.DeleteVal(security_pkg.GetAct, v.val_id,
					'Task period data deleted by initiatives module');
			END LOOP;
	
			-- Delete metric data from main system
			FOR i IN (
				SELECT ti.ind_sid
				  FROM task_ind_template_instance ti
				 WHERE ti.task_sid = in_task_sid
			) LOOP
				FOR v IN (
					SELECT val_id
					  FROM csr.val
					 WHERE region_sid = r.region_sid
					   AND ind_sid = i.ind_sid
				) LOOP
					csr.indicator_pkg.DeleteVal(security_pkg.GetAct, v.val_id,
						'Task metric data deleted by initiatives due to region change');
				END LOOP;
			END LOOP;
		END LOOP;
	
		-- If regions were added/changed then add a task job
		IF v_regions_changed > 0 THEN
			dependency_pkg.CreateJobForTask(in_task_sid);
		END IF;
	END IF;
	
	-- Amend the rest of the initiative (this data used to be on a separate page
	-- (and the code in SetInitiativeImpl is generic to both create and amend)
	SetInitiativeImpl(
		in_task_sid,
		v_start_dtm,
		v_end_dtm,
		in_one_off,
		in_project_team_valid,
		in_project_team_names,
		in_project_team_emails,
		in_sponsor_valid,
		in_sponsor_names,
		in_sponsor_emails,
		in_periodic_valid,
		in_periodic_ids,
		in_static_valid,
		in_static_ids,
		in_static_vals,
		in_static_uoms
	);

	-- Only generate a new reference if that option is
	-- enabled and the caller hasn't specified a reference.
	SELECT update_ref_on_amend
	  INTO v_update_ref_on_amend
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF in_ref IS NULL AND v_update_ref_on_amend != 0 THEN
		-- Generating new references may be desirable if the client uses 
		-- information that may have changed to generate the reference.
		AutoGenerateRef(in_task_sid, v_ref);
	END IF;
	
	-- Select current name and sid
	OPEN out_cur FOR
		SELECT task_sid, name, internal_ref reference
		  FROM task
		 WHERE task_sid = in_task_sid;
END;

PROCEDURE GetAllMetricColumnsForImport(
	out_static					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_static FOR
		SELECT DISTINCT it.ind_template_id, it.name, it.description, it.measure_sid, pit.pos_group, pit.pos,
		       DECODE(NVL(it.calculation, '<isnull/>'), '<isnull/>', it.is_npv, 1) is_calculated_value
		  FROM ind_template it, project_ind_template pit
		 WHERE it.ind_template_id = pit.ind_template_id
		   AND pit.update_per_period = 0
		   --AND it.calculation IS NULL
		   --AND it.is_npv = 0
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, pit.project_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY pit.pos_group, pit.pos, it.description;
END;

PROCEDURE GetMetricsForProject(
	in_project_sid				IN	security_pkg.T_SID_ID,
	out_periodic				OUT	SYS_REFCURSOR,
	out_static					OUT	SYS_REFCURSOR,
	out_uom						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- fetch metrics from project_ind_template
	-- use task_ind_template_instance to mark metric as selected (ind_sid not null)
	-- if metric has instance try to get the value as well

	OPEN out_periodic FOR
		SELECT it.ind_template_id, it.name, it.description, it.input_label, NULL ind_sid, 
			pit.pos_group, pit.pos, pit.input_dp, pit.is_mandatory, pit.display_context, 
			pit.saving_template_id, sav.name saving_template_name,
			pit.ongoing_template_id, ong.name ongoing_template_name,
			0 is_calculated_value, it.measure_sid
		  FROM ind_template it, project_ind_template pit, 
		  	   ind_template sav, ind_template ong
		 WHERE it.ind_template_id = pit.ind_template_id
		   AND it.calculation IS NULL
		   AND it.is_npv = 0
		   AND pit.project_sid = in_project_sid
		   AND pit.update_per_period = 1
		   AND sav.ind_template_id(+) = pit.saving_template_id
		   AND ong.ind_template_id(+) = pit.ongoing_template_id
		 ORDER BY pit.pos_group, pit.pos;

	OPEN out_static FOR
		SELECT t.ind_template_id, t.name, t.description, t.input_label, t.pos_group, t.pos, t.info_text,
			t.measure_sid, t.input_dp, t.is_mandatory, t.default_value, is_calculated_value, display_context,
			NULL ind_sid, NULL period_start_dtm, NULL period_end_dtm, NULL entry_measure_conversion_id, NULL val,
			NULL start_dtm, NULL end_dtm, NULL period_duration, t.is_group_mandatory, t.group_label, t.group_info_text, 
			is_ongoing, NULL ongoing_end_dtm
		  FROM (
	        SELECT it.ind_template_id, it.name, it.description, it.input_label, it.info_text, it.is_ongoing, pit.pos,
	        	pit.default_value, it.measure_sid, pit.pos_group, pit.input_dp, pit.is_mandatory, pit.display_context,
	        	CASE WHEN it.calculation IS NULL THEN it.is_npv ELSE 1 END is_calculated_value,
	        		itg.is_group_mandatory, itg.label group_label, itg.info_text group_info_text
	          FROM ind_template it, project_ind_template pit, ind_template_group itg
	         WHERE it.ind_template_id = pit.ind_template_id
	           -- We don't want to show calculated values on the create page
	           AND it.calculation IS NULL
	           AND it.is_npv = 0
	           AND pit.project_sid = in_project_sid
	           AND pit.update_per_period = 0
	           AND itg.project_sid = pit.project_sid
	           AND itg.pos_group = pit.pos_group
		    ) t
		 ORDER BY t.pos_group, t.pos;

	OPEN out_uom FOR
		SELECT DISTINCT m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM ind_template it, project_ind_template pit, csr.measure m, csr.measure_conversion mc
		 WHERE pit.project_sid = in_project_sid
		   AND it.ind_template_id = pit.ind_template_id
		   AND m.measure_sid = it.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid;
END;

-- Includes values for static metrics
PROCEDURE GetMetricsForTask(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_periodic				OUT	SYS_REFCURSOR,
	out_static					OUT	SYS_REFCURSOR,
	out_uom						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- fetch metrics from project_ind_template
	-- use task_ind_template_instance to mark metric as selected (ind_sid not null)
	-- if metric has instance try to get the value as well

	OPEN out_periodic FOR
		SELECT it.ind_template_id, it.name, it.description, it.input_label, inst.ind_sid,
			 pit.input_dp, pit.pos_group, pit.pos, pit.is_mandatory, pit.display_context,
			 pit.saving_template_id, sav.name saving_template_name,
			 pit.ongoing_template_id, ong.name ongoing_template_name,
			 0 is_calculated_value
		  FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst,
		  		ind_template sav, ind_template ong
		 WHERE it.ind_template_id = pit.ind_template_id
		   AND it.calculation IS NULL
		   AND it.is_npv = 0
		   AND pit.project_sid = t.project_sid
		   AND pit.update_per_period = 1
		   AND inst.task_sid(+) = in_task_sid
		   AND inst.from_ind_template_id(+) = it.ind_template_id
		   AND t.task_sid = in_task_sid
		   AND sav.ind_template_id(+) = pit.saving_template_id
		   AND ong.ind_template_id(+) = pit.ongoing_template_id
		 ORDER BY pit.pos_group, pit.pos;

	OPEN out_static FOR
		SELECT it.ind_template_id, it.name, it.description, it.input_label, inst.ind_sid, pit.pos_group, pit.pos, it.info_text,
			   it.measure_sid, inst.entry_measure_conversion_id, pit.default_value, pit.input_dp, pit.is_mandatory, pit.display_context,
			   NVL(inst.entry_val, inst.val) val, CASE WHEN it.calculation IS NULL THEN it.is_npv ELSE 1 END is_calculated_value,	
			   t.start_dtm, t.end_dtm, t.period_duration, tr.region_sid, itg.is_group_mandatory, itg.label group_label, itg.info_text group_info_text,
			   it.is_ongoing, inst.ongoing_end_dtm
          FROM task t, ind_template it, project_ind_template pit, ind_template_group itg, task_ind_template_instance inst, task_region tr
         WHERE it.ind_template_id = pit.ind_template_id
           -- We don't want to show calculated values on the create page
           AND it.calculation IS NULL
           AND it.is_npv = 0
           AND pit.project_sid = t.project_sid
           AND pit.update_per_period = 0
           AND itg.project_sid = pit.project_sid
           AND itg.pos_group = pit.pos_group
		   AND inst.from_ind_template_id = it.ind_template_id
		   AND t.task_sid = in_task_sid
		   AND t.task_sid = inst.task_sid
		   AND tr.task_sid = t.task_sid
		 ORDER BY pit.pos;

	OPEN out_uom FOR
		SELECT DISTINCT m.measure_sid, m.name, m.description, mc.measure_conversion_id, mc.description conversion_desc
		  FROM task_ind_template_instance inst, csr.ind i, csr.measure m, csr.measure_conversion mc
		 WHERE inst.task_sid = in_task_sid
		   AND i.ind_sid = inst.ind_sid
		   AND m.measure_sid = i.measure_sid
		   AND mc.measure_sid(+) = m.measure_sid;
END;

PROCEDURE GetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_details					OUT	SYS_REFCURSOR,
	out_team					OUT	SYS_REFCURSOR,
	out_sponsors				OUT	SYS_REFCURSOR,
	out_mt_periodic				OUT	SYS_REFCURSOR,
	out_mt_static				OUT	SYS_REFCURSOR,
	out_mt_uom					OUT	SYS_REFCURSOR
)
AS
BEGIN

	-- For initiative (single row):
	-- Get start and end dtm
	-- status_id (used to select radio button state, proposed, started, completed)
	-- Get one-off or ongoing savings (radio buttons on page)
	OPEN out_details FOR
		SELECT t.task_sid, t.internal_ref name, t.start_dtm, t.end_dtm, t.owner_sid,
			u.full_name, u.email, t.task_status_id, ts.label, ts.colour,
			ei.one_off_saving
		  FROM task t, task_status ts, csr.csr_user u, initiative_extra_info ei
		 WHERE t.task_sid = in_task_sid
		   AND ts.task_status_id = t.task_status_id
		   AND u.csr_user_sid = t.owner_sid
		   AND ei.task_sid(+) = t.task_sid;

	/*
	-- Get project team (from roles)
	OPEN out_team FOR
		SELECT u.csr_user_sid, u.full_name, u.email
		  FROM task t, task_role_member trm, role r, csr.csr_user u
		 WHERE t.task_sid = in_task_sid
		   AND r.app_sid = security_pkg.GetApp
		   AND LOWER(r.name) = 'project team'
		   AND trm.task_sid = t.task_sid
		   AND trm.project_sid = t.project_sid
		   AND trm.role_id = r.role_id
		   AND u.csr_user_sid = trm.user_or_group_sid;
	*/

	-- Get simple project team from the bespoke table
	OPEN out_team FOR
		SELECT name, email
		  FROM initiative_project_team
		 WHERE task_sid = in_task_sid
		 ORDER BY name;

	OPEN out_sponsors FOR
		SELECT name, email
		  FROM initiative_sponsor
		 WHERE task_sid = in_task_sid
		 ORDER BY name;

	-- Get list of metrics (these to include "people touched by project", "total spend" and "projected cost savings")
	-- NOTE: "people touched by initiative", "total spend" and "projected cost savings", should be set-up when the initiative is created?
	--       How are we storing this data, it's in an indicator but it needs to act like a global?
	GetMetricsForTask(in_task_sid, out_mt_periodic, out_mt_static, out_mt_uom);
END;

PROCEDURE SetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
)
AS
	v_start_dtm					task.start_dtm%TYPE;
	v_end_dtm					task.end_dtm%TYPE;
BEGIN
	-- Truncate input start and end dtm
	v_start_dtm := TRUNC(in_start_dtm, 'MONTH');
	v_end_dtm := TRUNC(in_end_dtm, 'MONTH');

	-- Modify initiative dates
	SetImplDates(
		in_task_sid,
		v_start_dtm,
		v_end_dtm
	);

	-- Set the metric values
	SetMetricValues(
		in_task_sid,
		in_start_dtm,
		in_end_dtm,
		in_static_ids,
		in_static_vals,
		in_static_uoms
	);
END;

PROCEDURE SetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	SetInitiativeImpl(
		in_task_sid,
		in_start_dtm,
		in_end_dtm,
		in_one_off,
		1, -- in_project_team_valid
		in_project_team_names,
		in_project_team_emails,
		1, -- in_sponsor_valid
		in_sponsor_names,
		in_sponsor_emails,
		1, -- in_periodic_valid
		in_periodic_ids,
		1, -- in_static_valid
		in_static_ids,
		in_static_vals,
		in_static_uoms
	);
END;

PROCEDURE SetInitiativeImpl(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_one_off					IN	NUMBER,
	in_project_team_valid		IN	NUMBER,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_valid			IN	NUMBER,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS,
	in_periodic_valid			IN	NUMBER,
	in_periodic_ids				IN	security_pkg.T_SID_IDS,
	in_static_valid				IN	NUMBER,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
)
AS
	v_start_dtm					task.start_dtm%TYPE;
	v_end_dtm					task.end_dtm%TYPE;
BEGIN
	-- Truncate input start and end dtm
	v_start_dtm := TRUNC(in_start_dtm, 'MONTH');
	v_end_dtm := TRUNC(in_end_dtm, 'MONTH');
	
	-- Extra info (one off or not)
	BEGIN
		INSERT INTO initiative_extra_info
			(task_sid, one_off_saving)
		  VALUES (in_task_sid, in_one_off);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE initiative_extra_info
			   SET one_off_saving = in_one_off
			 WHERE task_sid = in_task_sid;
	END;

	-- Modify initiative dates
	SetImplDates(
		in_task_sid,
		v_start_dtm,
		v_end_dtm
	);

	-- Set-up the project teams and project sponsors
	IF in_project_team_valid <> 0 AND in_sponsor_valid <> 0 THEN
		SetImplTeamAndSponsor(
			in_task_sid,
			in_project_team_names,
			in_project_team_emails,
			in_sponsor_names,
			in_sponsor_emails
		);
	END IF;
	
	-- Associate metrics with the initiative
	IF in_periodic_valid <> 0 THEN
		SetImplMetricsForTask(
			in_task_sid,
			in_periodic_ids
		);
	END IF;
	
	-- Set the metric values
	IF in_static_valid <> 0 THEN
		SetMetricValues(
			in_task_sid,
			in_start_dtm,
			in_end_dtm,
			in_static_ids,
			in_static_vals,
			in_static_uoms
		);
	END IF;
END;

PROCEDURE SetImplDates(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.end_dtm%TYPE
)
AS
	v_project_sid				security_pkg.T_SID_ID;
	v_project_start_dtm			project.start_dtm%TYPE;
	v_project_end_dtm			project.end_dtm%TYPE;
	v_task_start_dtm			task.start_dtm%TYPE;
	v_task_end_dtm				task.end_dtm%TYPE;
BEGIN
	security_pkg.debugmsg('SetImplDates: '||in_start_dtm||', '||in_end_dtm);
	
	-- Get project/task start/end dates
	SELECT p.project_sid, p.start_dtm, p.end_dtm, t.start_dtm, t.end_dtm
	  INTO v_project_sid, v_project_start_dtm, v_project_end_dtm, v_task_start_dtm, v_task_end_dtm
	  FROM project p, task t
	 WHERE t.task_sid = in_task_sid
	   AND p.project_sid = t.project_sid;

	-- Do we need to nudge the project times
	-- out to get the new timespan in?
	IF v_project_start_dtm > in_start_dtm THEN
		UPDATE project
		   SET start_dtm = in_start_dtm
		 WHERE project_sid = v_project_sid;
	END IF;

	-- Also nudge any parent initiative out
	-- to accommodate the new time span
	FOR r IN (
		SELECT task_sid
		  FROM task
		  	START WITH task_sid = in_task_sid
		  	CONNECT BY PRIOR parent_task_sid = task_sid
	) LOOP
		UPDATE task
		   SET start_dtm = CASE WHEN start_dtm > in_start_dtm THEN in_start_dtm ELSE start_dtm END,
			   end_dtm = CASE WHEN end_dtm < in_end_dtm THEN in_end_dtm ELSE end_dtm END
		 WHERE task_sid = r.task_sid;
	END LOOP;

	IF v_project_end_dtm < in_end_dtm THEN
		UPDATE project
		   SET end_dtm = in_end_dtm
		 WHERE project_sid = v_project_sid;
	END IF;

	-- Have the start or end dates 
	-- actually changed on the initiative
	IF v_task_start_dtm != in_start_dtm OR
	   v_task_end_dtm != in_end_dtm	THEN
	
		security_pkg.debugmsg('SetImplDates: setting task dates');
		
		-- Update the task table directly
		UPDATE task
		   SET start_dtm = in_start_dtm,
		       end_dtm = in_end_dtm
		 WHERE task_sid = in_task_sid;
		 
		-- Any NPV calculations associated with this 
		-- initiative will need to be recomputed
		ind_template_pkg.TriggerNPVRecalc(in_task_sid);   	
	END IF;
END;

PROCEDURE SetImplTeamAndSponsor(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS
)
AS
BEGIN
	-- Project team
	-- Delete existing values
	DELETE FROM initiative_project_team
	 WHERE task_sid = in_task_sid;

	-- Insert names and emails (assumes arrays are of same length)
	IF NOT (in_project_team_names.COUNT = 0 OR (in_project_team_names.COUNT = 1 AND in_project_team_names(1) IS NULL)) THEN
		FOR i IN in_project_team_names.FIRST .. in_project_team_names.LAST
		LOOP
			INSERT INTO initiative_project_team
				(task_sid, name, email)
			  VALUES (in_task_sid, in_project_team_names(i), in_project_team_emails(i));
		END LOOP;
	END IF;

	-- Initiative sponsor
	-- Delete existing values
	DELETE FROM initiative_sponsor
	 WHERE task_sid = in_task_sid;

	-- Insert names and emails (assumes arrays are of same length)
	IF NOT (in_sponsor_names.COUNT = 0 OR (in_sponsor_names.COUNT = 1 AND in_sponsor_names(1) IS NULL)) THEN
		FOR i IN in_sponsor_names.FIRST .. in_sponsor_names.LAST
		LOOP
			INSERT INTO initiative_sponsor
				(task_sid, name, email)
			  VALUES (in_task_sid, in_sponsor_names(i), in_sponsor_emails(i));
		END LOOP;
	END IF;
END;

PROCEDURE SetImplMetricsForTask(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_periodic_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_template_ids				security_pkg.T_SID_IDS;
	t_periodic_ids				security.T_SID_TABLE;
BEGIN
	-- Add periodic ids - built from input array
	IF NOT (in_periodic_ids.COUNT = 0 OR (in_periodic_ids.COUNT = 1 AND in_periodic_ids(1) IS NULL)) THEN
		FOR i IN in_periodic_ids.FIRST .. in_periodic_ids.LAST
		LOOP
			v_template_ids(v_template_ids.COUNT) := in_periodic_ids(i);
		END LOOP;
	END IF;

	-- Add static ids - built from the task_ind_template_instance table
	-- as input ids are only available if values are associated with
	-- the metric and we don't want to delete the metric just because
	-- the user didn't enter any data
	FOR r IN (
		SELECT from_ind_template_id
		  FROM task_ind_template_instance i, project_ind_template p, ind_template it
		 WHERE i.task_sid = in_task_sid
		   AND i.from_ind_template_id = p.ind_template_id
		   AND it.ind_template_id = i.from_ind_template_id
		   AND p.update_per_period = 0
		   AND it.calculation IS NULL
		   AND it.is_npv = 0
	) LOOP
		v_template_ids(v_template_ids.COUNT) := r.from_ind_template_id;
	END LOOP;

	-- Add calculations (not created until this point first time around so no instance entry)
	-- We have to make sure that if the calculation is from a merged template (assigned in the project ind template table)
	-- then we only create it if the associated "update_per_period" metric indicator has also been created (they can be un-checked in the UI).
	-- We also need to ensure that any calculations that are not from merged templates are created regardless.
	
	t_periodic_ids := security_pkg.SidArrayToTable(in_periodic_ids);
	
	FOR r IN (
		SELECT merged_template_id ind_template_id
		  FROM task t, TABLE(t_periodic_ids) inst, project_ind_template pit, ind_template it
		 WHERE t.task_sid = in_task_sid
		   AND pit.ind_template_id = inst.column_value
		   AND pit.project_sid = t.project_sid
		   AND pit.update_per_period = 1
		   AND it.ind_template_id = pit.merged_template_id
		   AND it.calculation IS NOT NULL
		UNION (
		SELECT it.ind_template_id ind_template_id
		  FROM task t, project_ind_template pit, ind_template it
		 WHERE t.task_sid = in_task_sid
		   AND pit.project_sid = t.project_sid
		   AND it.ind_template_id = pit.ind_template_id
		   AND it.calculation IS NOT NULL
		MINUS
		SELECT merged_template_id ind_template_id
		  FROM task t, project_ind_template pit
		 WHERE t.task_sid = in_task_sid
		   AND pit.project_sid = t.project_sid
		)
	) LOOP
		v_template_ids(v_template_ids.COUNT) := r.ind_template_id;
	END LOOP;
	
	-- Set task's metrics (this will delete metrics that
	-- are no longer present in the array for us)
	ind_template_pkg.SetMetricsForTask(in_task_sid, v_template_ids);
END;

PROCEDURE GetAllowedStatuses(
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_from_status_id			task_status.task_status_id%TYPE;
BEGIN
	BEGIN
		SELECT task_status_id
		  INTO v_from_status_id
		  FROM task
		 WHERE task_sid = in_task_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_from_status_id := -1;
	END;

	-- Fetch the allowed statuses
	GetAllowedStatusesFromStatus(v_from_status_id, out_cur);
END;

PROCEDURE GetAllowedStatusesFromStatus(
	in_from_status_id			IN	task_status.task_status_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Return the statuses this user is allowed to 
	-- set a task to based on the given status id
	OPEN out_cur FOR
		SELECT DISTINCT
			ts.task_status_id, ts.label, ts.note, NVL(tr.button_text, ts.label) button_text,
			ts.is_default, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts. means_terminated, ts.belongs_to_owner,
			tr.ask_for_comment, tr.save_data, tr.pos, tr.page_back, ts.is_draft
		  FROM task_status ts, task_status_transition tr, allow_transition atr,
		  	TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) act
		 WHERE ts.task_status_id = tr.to_task_status_id
		   AND NVL(tr.from_task_status_id, -1) = in_from_status_id
		   AND atr.task_status_transition_id = tr.task_status_transition_id
		   AND atr.user_or_group_sid = act.column_value
		   AND tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND atr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tr.pos;
END;

PROCEDURE GetAllowedStatusTransitions(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT
			tr.from_task_status_id,
			ts.task_status_id, ts.label, ts.note, NVL(tr.button_text, ts.label) button_text,
			ts.is_default, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts. means_terminated, ts.belongs_to_owner,
			tr.ask_for_comment, tr.save_data, tr.pos, tr.page_back, ts.is_draft
		  FROM task_status ts, task_status_transition tr, allow_transition atr,
		  	TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) act
		 WHERE ts.task_status_id = tr.to_task_status_id
		   AND atr.task_status_transition_id = tr.task_status_transition_id
		   AND atr.user_or_group_sid = act.column_value
		   AND tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND atr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY tr.from_task_Status_id NULLS FIRST, tr.pos;
END;

PROCEDURE SubmitForApproval(
	in_task_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	SetStatusFromLabel(in_task_sid, 'submitted', 'Summitted by initiatives module');
END;

PROCEDURE Approve(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment					IN	task_status_history.comment_text%TYPE
)
AS
BEGIN
	SetStatusFromLabel(in_task_sid, 'approved', in_comment);
END;

PROCEDURE Reject(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment					IN	task_status_history.comment_text%TYPE
)
AS
BEGIN
	SetStatusFromLabel(in_task_sid, 'rejected', in_comment);
END;

PROCEDURE Stop(
	in_task_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	SetStatusFromLabel(in_task_sid, 'stopped', 'Stopped by initiative tracker.');
END;

PROCEDURE Restart(
	in_task_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	SetStatusFromLabel(in_task_sid, 'approved', 'Initiative restarted from stopped state.');
END;

PROCEDURE SetStatus(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_to_task_status_id		IN	task_status.task_status_id%TYPE,
	in_comment					IN	task_status_history.comment_text%TYPE
)
AS
	v_from_task_status_id		task_status.task_status_id%TYPE;
	v_to_task_status_id			task_status.task_status_id%TYPE;
	v_transition_id				task_status_transition.task_status_transition_id%TYPE;
	v_means_completed			task_status.means_completed%TYPE;
	v_means_terminated			task_status.means_terminated%TYPE;
	v_means_back				task_status.means_back%TYPE;
BEGIN
	-- get the status ids
	SELECT task_status_id
	  INTO v_from_task_status_id
	  FROM task
	 WHERE task_sid = in_task_sid;
	 
	v_to_task_status_id := in_to_task_status_id;
	
	-- Is the user allowed to set this status or indeed is this transition allowed
	IF NOT IsSetStatusAllowed(v_from_task_status_id, v_to_task_status_id) THEN
		RAISE_APPLICATION_ERROR(ERR_SET_STATUS_DENIED, 'Set status denied for user with SID ' || security_pkg.GetSid || ' trying to set status with ID ' || v_to_task_status_id);
	END IF;
	
	-- means back to last status?
	SELECT means_back
	  INTO v_means_back
	  FROM task_status
	 WHERE task_status_id = in_to_task_status_id;
	
	IF v_means_back <> 0 THEN
		SELECT from_task_status_id
		  INTO v_to_task_status_id
		  FROM task_status_transition tr, task t
		 WHERE t.task_sid = in_task_sid
		   AND tr.task_status_transition_id = t.last_transition_id;
	END IF;
	
	-- This will raise an exception if the status is changing from 
	-- draft to non-draft and the mandatory fields are not filled in
	INTERNAL_CheckMandatoryFields(in_task_sid, v_from_task_status_id, v_to_task_status_id);

	-- Set the task status
	task_pkg.SetTaskStatus(security_pkg.GetACT, in_task_sid, v_to_task_status_id, NVL(in_comment, 'Status set by initiatives module'));

	-- Update the task with the transition id
	UPDATE task
	   SET last_transition_id = GetTransitionId(v_from_task_status_id, v_to_task_status_id)
	 WHERE task_sid = in_task_sid
	   AND app_sid = security_pkg.GetAPP;

	-- Does the status mean terminated or completed
	SELECT means_completed, means_terminated
	  INTO v_means_completed, v_means_terminated
	  FROM task_status
	 WHERE task_status_id = v_to_task_status_id;

	-- Complete or terminate as required
	IF v_means_completed = 1 THEN
		CompleteInitiative(in_task_sid);
	ELSIF v_means_terminated = 1 THEN
		TerminateInitiative(in_task_sid);
	END IF;

	-- Tell the scenario package the status changes as any 
	-- associated data cubes will need to be recomputed
	scenario_pkg.OnTaskStatusChanged(in_task_sid, v_from_task_status_id, v_to_task_status_id);
END;

PROCEDURE SetStatusFromLabel(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	task_status.label%TYPE,
	in_comment					IN	task_status_history.comment_text%TYPE
)
AS
	v_to_task_status_id			task_status.task_status_id%TYPE;
BEGIN
	v_to_task_status_id := StatusIdFromLabel(in_task_sid, in_label);
	SetStatus(in_task_sid, v_to_task_status_id, in_comment);
END;

FUNCTION StatusIdFromLabel(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_label					IN	task_status.label%TYPE
) RETURN task_status.task_status_id%TYPE
AS
	v_task_status_id			task_status.task_status_id%TYPE;
BEGIN
	-- Get the ID from the label
	SELECT ts.task_status_id
	  INTO v_task_status_id
	  FROM task_status ts, project_task_status pts, task t
	 WHERE t.task_sid = in_task_sid
	   AND pts.project_sid = t.project_sid
	   AND ts.task_status_id = pts.task_status_id
	   AND LOWER(ts.label) = LOWER(in_label);

	RETURN v_task_status_id;
END;


FUNCTION GetTransitionId (
	in_from_task_status_id		IN	task_status.task_status_id%TYPE,
	in_to_task_status_id		IN	task_status.task_status_id%TYPE
) RETURN task_status_transition.task_status_transition_id%TYPE
AS
	v_transition_id				task_status_transition.task_status_transition_id%TYPE;
BEGIN
	BEGIN
		SELECT tr.task_status_transition_id
		  INTO v_transition_id
		  FROM task_status_transition tr
		 WHERE tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tr.from_task_status_id = in_from_task_status_id
		   AND tr.to_task_status_id = in_to_task_status_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;

	RETURN v_transition_id;
END;


FUNCTION IsSetStatusAllowed(
	in_from_task_status_id		IN	task_status.task_status_id%TYPE,
	in_to_task_status_id		IN	task_status.task_status_id%TYPE
) RETURN BOOLEAN
AS
	v_count						NUMBER;
	v_default					task_status.task_status_id%TYPE;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM task_status_transition tr, allow_transition atr, TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) a
	 WHERE tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND NVL(tr.from_task_status_id, -1) = NVL(in_from_task_status_id, -1)
	   AND NVL(tr.to_task_status_id, -1) = NVL(in_to_task_status_id, -1)
	   AND atr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND atr.task_status_transition_id = tr.task_status_transition_id
	   AND atr.user_or_group_sid = a.column_value;
	
	-- The check failed but if both the from and to status ids are the
	-- default status then check for allowed transitions from null -> default
	-- (the initial creation step will have set the task status to its default value)
	IF v_count = 0 THEN
		-- Get the default status id
		BEGIN
			SELECT task_status_id
			  INTO v_default
			  FROM task_status
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND is_default = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_default := NULL;
		END;
		
		IF v_default IS NOT NULL AND 
		   in_from_task_status_id = v_default AND 
		   in_to_task_status_id = v_default THEN	
		   	
			SELECT COUNT(*)
			  INTO v_count
			  FROM task_status_transition tr, allow_transition atr, TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) a
			 WHERE tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND tr.from_task_status_id IS NULL
			   AND tr.to_task_status_id = v_default
			   AND atr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   and atr.task_status_transition_id = tr.task_status_transition_id
			   AND atr.user_or_group_sid = a.column_value;
		END IF;
	END IF;

	RETURN v_count > 0;
END;

PROCEDURE GetMyInitiatives(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_group_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_group_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Regional Co-ordinators');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	-- Regional coordinators will be able to see all initiatives under their
	-- region mount point, or the root region if they don't have a mount point set.
	IF v_group_sid IS NOT NULL AND
	   security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_group_sid, security_pkg.PERMISSION_WRITE) THEN

		SELECT COUNT(/*DISTINCT*/ t.task_sid)
		  INTO out_total_rows
		  FROM task t, task_region tr, (
			    SELECT so.sid_id
			      FROM security.securable_object so
			        START WITH sid_id IN (SELECT region_sid FROM csr.region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
			        CONNECT BY PRIOR sid_id = parent_sid_id
			    ) rgn
		 WHERE t.task_sid = tr.task_sid
		   AND tr.region_sid = rgn.sid_id;

		OPEN out_cur FOR
			SELECT x.*, TRUNC(SYSDATE, 'MONTH') current_month
			  FROM (
	                SELECT rownum rn, q.*
					  FROM (
		                        SELECT t.task_sid, t.project_sid, p.name project_name, t.name task_name, t.internal_ref task_reference, t.start_dtm, t.end_dtm,
		                        	csr.stragg(tag.tag) tags, ts.task_status_id, ts.label task_status_label, t.created_dtm
								  FROM task t, task_tag tt, tag, project p, task_status ts, task_region tr, (
									    SELECT so.sid_id
									      FROM security.securable_object so
									        START WITH sid_id IN (SELECT region_sid FROM csr.region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
									        CONNECT BY PRIOR sid_id = parent_sid_id
									    ) rgn
								 WHERE t.task_sid = tr.task_sid
								   AND tr.region_sid = rgn.sid_id
								   AND t.task_sid = tt.task_sid(+)
		                           AND tt.tag_id = tag.tag_id(+)
		                           AND t.project_sid = p.project_sid
		                           AND ts.task_status_id = t.task_status_id
								 GROUP BY t.task_sid, t.project_sid, p.name, t.name, t.internal_ref, t.start_dtm, t.end_dtm, ts.task_status_id, ts.label, t.created_dtm
								 ORDER BY t.created_dtm DESC, t.internal_ref ASC
	                    ) q
					  WHERE rownum <= in_start_row + in_page_size
	            ) x
			  WHERE rn > in_start_row;
	ELSE
		-- This user is not a regional coordinator (or an admin), only select their tasks
		SELECT COUNT(*)
		  INTO out_total_rows
		  FROM task
		 WHERE owner_sid = security_pkg.GetSid; --SYS_CONTEXT('SECURITY', 'SID');

		OPEN out_cur FOR
			SELECT x.*, TRUNC(SYSDATE, 'MONTH') current_month
			  FROM (
	                SELECT rownum rn, q.*
					  FROM (
		                        SELECT t.task_sid, t.project_sid, p.name project_name, t.name task_name, t.internal_ref task_reference, t.start_dtm, t.end_dtm,
		                        	csr.stragg(tag.tag) tags, ts.task_status_id, ts.label task_status_label, t.created_dtm
								  FROM task t, task_tag tt, tag, project p, task_status ts
								 WHERE t.owner_sid = SYS_CONTEXT('SECURITY','SID')
		                           AND t.task_sid = tt.task_sid(+)
		                           AND tt.tag_id = tag.tag_id(+)
		                           AND t.project_sid = p.project_sid
		                           AND ts.task_status_id = t.task_status_id
								 GROUP BY t.task_sid, t.project_sid, p.name, t.name, t.internal_ref, t.start_dtm, t.end_dtm, ts.task_status_id, ts.label, t.created_dtm
								 ORDER BY t.created_dtm DESC, t.internal_ref ASC
	                    ) q
					  WHERE rownum <= in_start_row + in_page_size
	            ) x
			  WHERE rn > in_start_row;
	END IF;
END;

PROCEDURE GetUsersCoordinatorDetails(
	in_user_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read user with sid ' || in_user_sid);
	END IF;

	OPEN out_cur FOR
		SELECT DISTINCT cou.csr_user_sid, cou.user_name, cou.friendly_name, cou.full_name name, cou.email
		  FROM csr.role rl, csr.region_role_member rm, csr.csr_user cou, csr.region_start_point inrsp
		 WHERE rm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rl.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(rl.name) = 'initiative approver (rc)'
		   AND rm.role_sid = rl.role_sid
		   AND cou.csr_user_sid = rm.user_sid
		   AND inrsp.user_sid = in_user_sid
		   AND rm.region_sid = inrsp.region_sid;
END;

PROCEDURE GetLastTransition (
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
As
BEGIN
	OPEN out_cur FOR
		SELECT tr.task_status_transition_id, tr.from_task_status_id, tr.to_task_status_id, tr.alert_type_id
		  FROM task_status_transition tr, task t
		 WHERE task_status_transition_id = t.last_transition_id
		   AND t.task_sid = in_task_sid
		   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tr.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAlertData (
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_alert_details			OUT	SYS_REFCURSOR,
	out_recipients				OUT	SYS_REFCURSOR,
	out_regions					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read task with sid ' || in_task_sid);
	END IF;

	-- Fetch initiative data (one row)
	OPEN out_alert_details FOR
		SELECT x.submitted_by_full_name, x.submitted_by_friendly_name, x.submitted_by_user_name, x.submitted_by_email,
		       x.name, x.internal_ref reference, x.start_dtm, x.end_dtm, x.host, x.host_secure, pt.name initiative_sub_type,
		       tr.button_text transition_name, fts.label from_status_name, tts.label to_status_name
		  FROM (
		    SELECT t.task_sid,
		           su.full_name submitted_by_full_name,
		           su.friendly_name submitted_by_friendly_name,
		           su.user_name submitted_by_user_name,
		           su.email submitted_by_email,
		     	   t.name,
		     	   t.internal_ref,
		     	   t.start_dtm,
		     	   t.end_dtm,
		     	   NVL(co.initiatives_host, cus.host) host,
		     	   NVL(ws.secure_only, 1) host_secure,
		     	   t.last_transition_id,
		     	   t.parent_task_sid
		     FROM task t
				JOIN csr.csr_user su ON t.owner_sid = su.csr_user_sid
				JOIN customer_options co ON su.app_sid = co.app_sid
				JOIN csr.customer cus ON co.app_sid = cus.app_sid
				LEFT JOIN security.website ws ON NVL(co.initiatives_host, cus.host) = ws.website_name
		    WHERE t.task_sid = in_task_sid
		      AND co.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) x, task_status_transition tr, task_status fts, task_status tts, task pt
		 WHERE tr.task_status_transition_id(+) = x.last_transition_id
		   AND fts.task_status_id(+) = tr.from_task_status_id
		   AND tts.task_status_id(+) = tr.to_task_status_id
		   AND pt.task_sid(+) = x.parent_task_sid
		;

	OPEN out_recipients FOR
		SELECT DISTINCT u.user_name to_user_name,
			   u.friendly_name to_friendly_name,
			   u.full_name to_full_name,
			   u.email to_email
		  FROM csr.csr_user u, (
		  	-- The user is associated with a region/role that corresponds to the current status
			SELECT DISTINCT rrm.user_sid
			    FROM task t, task_region tr, task_status ts, task_status_role tsr, csr.region_role_member rrm, security.user_table ut
			   WHERE t.task_sid = in_task_sid
			     AND ts.task_status_id = t.task_status_id
			     AND tr.task_sid = t.task_sid
			     AND rrm.region_sid = tr.region_sid
			     AND tsr.task_status_id = ts.task_status_id
			     AND tsr.role_sid = rrm.role_sid
			     AND ut.sid_id = rrm.user_sid
			     AND ut.account_enabled = 1
			     AND tsr.generate_alerts = 1
			  UNION
			  -- The user is associated with a project/region/role that corresponds to the current status
			  SELECT DISTINCT rrm.user_sid
			  FROM task t, task_region tr, task_status ts, task_status_role tsr, project_region_role_member rrm, security.user_table ut
			   WHERE t.task_sid = in_task_sid
			     AND ts.task_status_id = t.task_status_id
			     AND tr.task_sid = t.task_sid
			     AND rrm.region_sid = tr.region_sid
			     AND rrm.project_sid = t.project_sid
			     AND tsr.task_status_id = ts.task_status_id
			     AND tsr.role_sid = rrm.role_sid
			     AND ut.sid_id = rrm.user_sid
			     AND ut.account_enabled = 1
			     AND tsr.generate_alerts = 1
			  UNION
			  -- The user is associated with a task/role that corresponds to the current status (regardless of region)
			  SELECT trm.user_sid
			    FROM task t, task_region tr, task_status ts, task_status_role tsr, csr_task_role_member trm, security.user_table ut
			   WHERE t.task_sid = in_task_sid
			     AND ts.task_status_id = t.task_status_id
			     AND tr.task_sid = t.task_sid
			     AND trm.task_sid = t.task_sid
			     AND tsr.task_status_id = ts.task_status_id
		     	 AND tsr.role_sid = trm.role_sid
		     	 AND ut.sid_id = trm.user_sid
			     AND ut.account_enabled = 1
			     AND trm.generate_alerts = 1
			  UNION
			  -- The user is the owner and the current status specifies that the task belongs to the owner
			  SELECT t.owner_sid user_sid
			    FROM task t, task_region tr, task_status ts
			   WHERE t.task_sid = in_task_sid
			     AND ts.task_status_id = t.task_status_id
			     AND tr.task_sid(+) = t.task_sid
			     AND ts.belongs_to_owner = 1
			  UNION
			  -- The status means rejected (a rejected status may not belong to the owner but the user should still get an alert)
		   	  SELECT t.owner_sid user_sid
		        FROM task t, task_region tr, task_status ts
		       WHERE t.task_sid = in_task_sid
		         AND ts.task_status_id = t.task_status_id
		         AND tr.task_sid(+) = t.task_sid
		         AND ts.is_rejected = 1
		) x
		WHERE u.csr_user_sid = x.user_sid;

	OPEN out_regions FOR
		SELECT r.description region_desc
		  FROM task_region tr, csr.v$region r
		 WHERE tr.task_sid = in_task_sid
		   AND r.region_sid = tr.region_sid
		   AND r.region_sid = tr.region_sid;
END;

PROCEDURE GetMonthsForInitiative(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_restrict_future			IN	NUMBER,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_cur_month					DATE;
BEGIN
	v_cur_month := TRUNC(SYSDATE, 'MONTH');

	OPEN out_cur FOR
		SELECT month, DECODE (v_cur_month, month, 1, 0) this_month
		  FROM (
			SELECT ADD_MONTHS(TRUNC(start_dtm, 'MONTH'), LEVEL-1) month
			  FROM (
			  		SELECT start_dtm, end_dtm
			  		  FROM task
			  		 WHERE task_sid = in_task_sid
			  	)
			    CONNECT BY LEVEL <= (
			    	SELECT
			    		CASE WHEN end_dtm <= v_cur_month THEN
							MONTHS_BETWEEN(end_dtm, start_dtm)
						ELSE
							MONTHS_BETWEEN(DECODE(in_restrict_future, 0, end_dtm, ADD_MONTHS(v_cur_month, 1)), start_dtm)
						END last
					  FROM task
				  	 WHERE task_sid = in_task_sid
			    )
		) ORDER BY month;
END;

PROCEDURE SaveDataEntry(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_month_dtm				IN	task.start_dtm%TYPE,
	in_progress_pct				IN	csr.val.val_number%TYPE,
	in_ids						IN	security_pkg.T_SID_IDS,
	in_vals						IN	T_VALUES,
	in_uoms						IN	security_pkg.T_SID_IDS
)
AS
	v_ind_sid					security_pkg.T_SID_ID;
	v_val_id					csr.val.val_id%TYPE;
	v_factor_a					csr.measure_conversion.a%TYPE;
	v_factor_b					csr.measure_conversion.b%TYPE;
	v_factor_c					csr.measure_conversion.c%TYPE;
	v_region_count				NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_region_count
	  FROM task_region
	 WHERE task_sid = in_task_sid;

	-- Set task progress for all regions
	FOR r IN (
		SELECT region_sid
		  FROM task_region
		 WHERE task_sid = in_task_sid
	) LOOP
		task_pkg.SetTaskPeriod(
			security_pkg.GetAct,
			in_task_sid,
			in_month_dtm,
			r.region_sid,
			NULL,
			NULL,
			in_progress_pct
		);
	END LOOP;

	IF NOT (in_ids.COUNT = 1 AND in_ids(1) IS NULL) THEN
		FOR i IN in_ids.FIRST .. in_ids.LAST
		LOOP
			-- Get the ind sid
			SELECT ind_sid
			  INTO v_ind_sid
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
			   AND from_ind_template_id = in_ids(i);

			-- Get the unit factor
			v_factor_a := 1;
			v_factor_b := 1;
			v_factor_c := 0;
			IF in_uoms(i) > -1 THEN
				SELECT mc.a, mc.b, mc.c
				  INTO v_factor_a, v_factor_b, v_factor_c
				  FROM csr.measure_conversion mc
				 WHERE mc.measure_conversion_id = in_uoms(i);
			END IF;

			-- For each region associated with the task...
			FOR r IN (
				SELECT region_sid
				  FROM task_region
				 WHERE task_sid = in_task_sid
			) LOOP
				-- Set the indicator value
				IF v_factor_a = 1 AND v_factor_b = 1 AND v_factor_c = 0 THEN
					csr.indicator_pkg.SetValue(
						security_pkg.GetAct,
						v_ind_sid,
						r.region_sid,
						in_month_dtm,
						ADD_MONTHS(in_month_dtm, 1),
						in_vals(i) / v_region_count,
						0,
						csr.csr_data_pkg.SOURCE_TYPE_DIRECT,
						NULL,
						NULL,
						NULL,
						0,
						NULL,
						v_val_id
					);
				ELSE
					csr.indicator_pkg.SetValue(
						security_pkg.GetAct,
						v_ind_sid,
						r.region_sid,
						in_month_dtm,
						ADD_MONTHS(in_month_dtm, 1),
						(v_factor_a * POWER(in_vals(i), v_factor_b) + v_factor_c) / v_region_count,
						0,
						csr.csr_data_pkg.SOURCE_TYPE_DIRECT,
						NULL,
						in_uoms(i),
						in_vals(i) / v_region_count,
						0,
						NULL,
						v_val_id
					);
				END IF;
			END LOOP;
		END LOOP;
	END IF;
END;

PROCEDURE GetReminderAlerts (
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Everything for this app, rely on RLS

	-- Fetch initiative data
	OPEN out_cur FOR
		SELECT task_sid, task_period_status_id, means_pct_complete, last_period_dtm
		  FROM (
		    SELECT t.task_sid, tp.task_period_status_id, tps.means_pct_complete,
            tp.start_dtm,  MAX(tp.start_dtm) over (partition by t.task_sid) last_period_dtm
		     FROM task t, task_period tp, customer_options co, task_period_status tps
		    WHERE tp.task_sid(+) = t.task_sid
          AND tps.task_period_status_id(+) = tp.task_period_status_id
		      AND co.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		      AND co.initiative_reminder_alerts <> 0
		)
		WHERE NVL(means_pct_complete, 0) < 1
      	  AND (
      	  		start_dtm  IS NULL
      	  	 OR start_dtm = last_period_dtm
      	  )
		  AND (
		  		last_period_dtm IS NULL
		  	 OR last_period_dtm < ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), -1)
		  );
END;

PROCEDURE GetNewInitiativeProps (
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Everything for this app, rely on RLS
	OPEN out_cur FOR
		SELECT t.task_sid, tr.region_sid
		  FROM task_region tr, task t
		 WHERE t.created_dtm >= ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), -1)
		   AND tr.task_sid = t.task_sid;
END;

-- Includes ongoing metrics
PROCEDURE GetInitiativeStaticData (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_regons			OUT	SYS_REFCURSOR,
	out_static			OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetInitiativeDetails(in_task_sid, out_task);
	
	OPEN out_regons FOR
		SELECT region_sid
		  FROM task_region
		 WHERE task_sid = in_task_sid;

	OPEN out_static FOR
		SELECT ti.ind_sid, tpl.ind_template_id, tpl.name, tpl.description, tpl.input_label, pit.input_dp, pit.saving_template_id, 
				tpl.per_period_duration, tpl.is_ongoing, ti.ongoing_end_dtm 	-- added
				--tpl.period, tpl.ongoing_period 							    -- removed
		  FROM task t, ind_template tpl, task_ind_template_instance ti, project_ind_template pit
		 WHERE t.task_Sid = in_task_sid
		   AND ti.task_sid = t.task_sid
		   AND tpl.ind_template_id = ti.from_ind_template_id
		   AND pit.ind_template_id = tpl.ind_template_id
		   AND pit.project_sid = t.project_sid
		   AND pit.update_per_period = 0
		   AND tpl.calculation IS NULL
		   AND tpl.is_npv = 0;
END;

PROCEDURE GetInitiativeProgressData (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_regons			OUT	SYS_REFCURSOR,
	out_static			OUT	SYS_REFCURSOR,
	out_periodic		OUT	SYS_REFCURSOR
	--,out_ongoing			OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetInitiativeDetails(in_task_sid, out_task);

	OPEN out_regons FOR
		SELECT region_sid
		  FROM task_region
		 WHERE task_sid = in_task_sid;

	OPEN out_static FOR
		SELECT ti.ind_sid, tpl.ind_template_id, tpl.name, tpl.description, tpl.input_label, pit.input_dp, pit.saving_template_id, 
			tpl.per_period_duration, tpl.is_ongoing, ti.ongoing_end_dtm 	-- added
			--tpl.period													-- removed
		  FROM task t, ind_template tpl, task_ind_template_instance ti, project_ind_template pit
		 WHERE t.task_Sid = in_task_sid
		   AND ti.task_sid = t.task_sid
		   AND tpl.ind_template_id = ti.from_ind_template_id
		   AND pit.ind_template_id = tpl.ind_template_id
		   AND pit.project_sid = t.project_sid
		   AND tpl.is_ongoing = 0
		   AND pit.update_per_period = 0
		   AND tpl.calculation IS NULL
		   AND tpl.is_npv = 0;

	OPEN out_periodic FOR
		SELECT ti.ind_sid, tpl.ind_template_id, tpl.name, tpl.description, tpl.input_label, pit.input_dp, pit.saving_template_id, 
			tpl.per_period_duration, tpl.is_ongoing, ti.ongoing_end_dtm		-- added
			--tpl.period													-- removed
		  FROM task t, ind_template tpl, task_ind_template_instance ti, project_ind_template pit
		 WHERE t.task_Sid = in_task_sid
		   AND ti.task_sid = t.task_sid
		   AND tpl.ind_template_id = ti.from_ind_template_id
		   AND pit.ind_template_id = tpl.ind_template_id
		   AND pit.project_sid = t.project_sid
		   AND tpl.is_ongoing = 0
		   AND pit.update_per_period = 1
		   AND tpl.calculation IS NULL
		   AND tpl.is_npv = 0
		 UNION
		SELECT t.output_ind_sid ind_sid, tpl.ind_template_id, tpl.name, tpl.description, tpl.input_label, 0 input_dp, 
			NULL saving_template_id, NULL per_period_duration, 0 is_ongoing, NULL ongoing_end_dtm
		  FROM ind_template tpl, task t
		 WHERE t.task_sid = in_task_sid
		   AND LOWER(tpl.name) = 'action_progress';
END;

PROCEDURE SaveProgressData(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_ind_sids			IN	security_pkg.T_SID_IDS,
	in_start_dtms		IN	T_DATES,
	in_vals				IN	T_VALUES
)
AS
	v_period_duration	task.period_duration%TYPE;
	v_progress_ind_sid	security_pkg.T_SID_ID;
	v_val_id			csr.val.val_id%TYPE;
BEGIN
	-- We assume that all 'arrays' have the same length so we
	-- can perform checks like this on just one of them
	IF (in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL)) THEN
		RETURN;
	END IF;

	-- Collect the progress data into a usable structure
	-- ...

	DELETE FROM progress_data;

	FOR i IN in_region_sids.FIRST .. in_region_sids.LAST
	LOOP
		INSERT INTO progress_data
		  (idx, region_sid)
		  	VALUES (i, in_region_sids(i));
	END LOOP;

	FOR i IN in_ind_sids.FIRST .. in_ind_sids.LAST
	LOOP
		UPDATE progress_data
		   SET ind_sid = in_ind_sids(i)
		 WHERE idx = i;
	END LOOP;

	FOR i IN in_start_dtms.FIRST .. in_start_dtms.LAST
	LOOP
		UPDATE progress_data
		   SET period_start_dtm = in_start_dtms(i)
		 WHERE idx = i;
	END LOOP;

	FOR i IN in_vals.FIRST .. in_vals.LAST
	LOOP
		UPDATE progress_data
		   SET val = in_vals(i)
		 WHERE idx = i;
	END LOOP;

	-- Extract the action progress indicator
	SELECT output_ind_sid, period_duration
	  INTO v_progress_ind_sid, v_period_duration
	  FROM task
	 WHERE task_sid = in_task_sid;

	-- Update task progress data
	FOR r IN (
		SELECT region_sid, ind_sid, period_start_dtm, val
		  FROM progress_data
		 WHERE ind_sid = v_progress_ind_sid
	) LOOP
		task_pkg.SetTaskPeriod(
			security_pkg.GetAct,
			in_task_sid,
			r.period_start_dtm,
			r.region_sid,
			CASE WHEN r.val IS NULL THEN -1 ELSE NULL END,
			NULL,
			NVL(r.val, -1)
		);
	END LOOP;

	-- Update the metric values
	FOR r IN (
		SELECT region_sid, ind_sid, period_start_dtm, val
		  FROM progress_data
		 WHERE ind_sid <> v_progress_ind_sid
	) LOOP
		csr.indicator_pkg.SetValue(
			security_pkg.GetACT,
			r.ind_sid,
			r.region_sid,
			r.period_start_dtm,
			ADD_MONTHS(r.period_start_dtm, v_period_duration),
			r.val,
			0,
			csr.csr_data_pkg.SOURCE_TYPE_DIRECT,
			NULL,
			NULL,
			NULL,
			0,
			NULL,
			v_val_id
		);
	END LOOP;
END;

PROCEDURE GetMyInitiatives2(
	out_projects		OUT	SYS_REFCURSOR,
	out_statuses		OUT	SYS_REFCURSOR,
	out_initiatives		OUT	SYS_REFCURSOR,
	out_options			OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetMyInitiatives2(
		NULL,
		out_projects,
		out_statuses,
		out_initiatives,
		out_options
	);
END;

PROCEDURE GetMyInitiatives2(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_projects					OUT	SYS_REFCURSOR,
	out_statuses					OUT	SYS_REFCURSOR,
	out_initiatives					OUT	SYS_REFCURSOR,
	out_options						OUT	SYS_REFCURSOR
)
AS
	v_root_region_sids				security.T_SID_TABLE;
BEGIN
	OPEN out_projects FOR
		SELECT project_sid, name, icon
		  FROM project
		 WHERE app_sid = security_pkg.GetAPP
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, project_sid, security_pkg.PERMISSION_READ) = 1;

	OPEN out_statuses FOR
		-- Any statuses the user is associated with by role
		SELECT DISTINCT ts.task_status_id, ts.label, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts.means_terminated, ts.belongs_to_owner, ts.colour, ts.is_draft
		  FROM task_status ts, task_status_role tsr, csr.region_role_member rrm
		 WHERE ts.app_sid = security_pkg.GetAPP
		   AND tsr.app_sid = security_pkg.GetAPP
		   AND tsr.task_status_id = ts.task_status_id
		   AND tsr.role_sid = rrm.role_sid
       	   AND rrm.inherited_from_sid = rrm.region_sid
		   AND rrm.user_sid =  SYS_CONTEXT('SECURITY', 'SID')
		UNION
		-- Any statuses the user is associated with by project role
		SELECT DISTINCT ts.task_status_id, ts.label, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts.means_terminated, ts.belongs_to_owner, ts.colour, ts.is_draft
		  FROM task_status ts, task_status_role tsr, project_region_role_member rrm
		 WHERE ts.app_sid = security_pkg.GetAPP
		   AND tsr.app_sid = security_pkg.GetAPP
		   AND tsr.task_status_id = ts.task_status_id
		   AND tsr.role_sid = rrm.role_sid
       	   AND rrm.inherited_from_sid = rrm.region_sid
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		UNION
		-- And any statuses associated with tasks the user can see 
		-- (defined by the rules of the v$user_initiatives view)
		SELECT ts.task_status_id, ts.label, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts.means_terminated, ts.belongs_to_owner, ts.colour, ts.is_draft
		  FROM task_status ts, v$user_initiatives t
		 WHERE ts.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ts.task_status_id = t.task_status_id
		-- And any statuses the user is allowed to transition from
		-- And that "belongs to owner" or "owner can see"
		UNION
		SELECT ts.task_status_id, ts.label, ts.is_live, ts.is_rejected, ts.is_stopped,
			ts.means_completed, ts.means_terminated, ts.belongs_to_owner, ts.colour, ts.is_draft
		  FROM task_status ts, task_status_transition tr, allow_transition atr
		  --,TABLE(act_pkg.GetUsersAndGroupsInACT(SYS_CONTEXT('SECURITY', 'ACT'))) act
	     WHERE ts.task_status_id = tr.from_task_status_id
	       -- XXX: I don't think the user needs to be able to make transitions from a state to be 
	       -- able to see that state when flagged as "belongs to owner" or "owner can see"
	       --AND atr.task_status_transition_id = tr.task_status_transition_id
	       --AND atr.user_or_group_sid = act.column_value
	       AND tr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND atr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND (ts.belongs_to_owner = 1
	         OR ts.owner_can_see = 1
	       );

	-- Get root region sids
	IF in_region_sid IS NOT NULL THEN
		v_root_region_sids := security.T_SID_TABLE();
		v_root_region_sids.extend;
		v_root_region_sids(v_root_region_sids.count) := in_region_sid;
	ELSE
		SELECT region_sid
		  BULK COLLECT INTO v_root_region_sids
		  FROM csr.region_start_point
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');
	END IF;
	 
	OPEN out_initiatives FOR
		SELECT DISTINCT x.*, TRUNC(SYSDATE, 'MONTH') current_month, TRUNC(SYSDATE, 'DDD') current_day,
        	CASE
        		WHEN (x.created_dtm + co.initiative_new_days) >= TRUNC(SYSDATE, 'DDD')
        		THEN 1
        		ELSE 0
        	END is_new,
        	CASE
    			WHEN x.last_task_period_dtm IS NULL
    			 AND start_dtm <= TRUNC(SYSDATE, 'MONTH')
    			THEN 1
        		WHEN TRUNC(SYSDATE, 'DDD') < end_dtm
        		 AND start_dtm <= TRUNC(SYSDATE, 'MONTH')
        		 AND ADD_MONTHS(x.last_task_period_dtm, x.period_duration) < TRUNC(SYSDATE, 'MONTH')
        		THEN 1
        		ELSE 0
        	END is_overdue
          FROM customer_options co, (
            SELECT t.task_sid, t.project_sid, p.name project_name, t.name task_name, t.internal_ref task_reference, t.start_dtm, t.end_dtm,
            	csr.stragg(tag.tag) tags, t.task_status_id, t.task_status_label, t.created_dtm, t.period_duration, t.last_task_period_dtm,
            	t.means_completed, t.means_terminated, t.is_live, t.is_rejected, t.is_stopped, p.icon project_icon
			  FROM v$user_initiatives t, task_tag tt, tag, project p
			 WHERE tt.task_sid(+) = t.task_sid
               AND tag.tag_id(+) = tt.tag_id
               AND p.project_sid = t.project_sid
			 GROUP BY t.task_sid, t.project_sid, p.name, t.name, t.internal_ref, t.start_dtm, t.end_dtm,
				t.task_status_id, t.task_status_label, t.created_dtm, t.period_duration, t.last_task_period_dtm,
				t.means_completed, t.means_terminated, t.is_live, t.is_rejected, t.is_stopped, p.icon
			 ORDER BY LOWER(t.name), LOWER(t.internal_ref) ASC, t.created_dtm DESC
		  ) x, (
		  	SELECT task_sid, CONNECT_BY_ISLEAF is_leaf
		  	  FROM task
		  	 	START WITH parent_task_sid IS NULL
		  	 	CONNECT BY PRIOR task_sid = parent_task_sid
		  ) y, (
		  	SELECT region_sid
		  	  FROM csr.region
		  	 START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_region_sids))
		  	 CONNECT BY PRIOR region_sid = parent_sid
		  ) r, task_region tr
		 WHERE co.app_sid = security_pkg.GetAPP
		   AND x.task_sid = y.task_sid
		   AND y.is_leaf = 1
		   AND tr.task_sid = y.task_sid
		   AND tr.region_sid = r.region_sid;

	OPEN out_options FOR
		SELECT my_initiatives_options
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetAPP;
END;

PROCEDURE AddIssue (
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_label				IN  csr.issue.label%TYPE,
	out_issue_id			OUT csr.issue.issue_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_task_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write task with sid ' || in_task_sid);
	END IF;

	csr.issue_pkg.CreateIssue(
		in_label => in_label,
		in_source_label => NULL,
		in_issue_type_id => 1,
		in_region_sid => NULL,
		out_issue_id => out_issue_id
	);

	INSERT INTO csr.issue_action (
		issue_action_id, task_sid)
	VALUES (
		csr.issue_action_id_seq.NEXTVAL, in_task_sid
	);

	UPDATE csr.issue
	   SET issue_action_id = csr.issue_action_id_seq.CURRVAL
	 WHERE issue_id = out_issue_id;
END;

PROCEDURE RegionSidsFromRefs (
	in_dummy		IN	NUMBER,
	in_refs			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_table			security.T_VARCHAR2_TABLE;
BEGIN
	v_table := security_pkg.Varchar2ArrayToTable(in_refs);

	OPEN out_cur FOR
		SELECT r.region_sid
		  FROM csr.region r, TABLE(v_table) t
		 WHERE r.lookup_key = t.value
		    AND r.active = 1;
END;

PROCEDURE RegionSidsFromNames (
	in_dummy		IN	NUMBER,
	in_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_table			security.T_VARCHAR2_TABLE;
	v_region_root	security_pkg.T_SID_ID;
BEGIN
	v_table := security_pkg.Varchar2ArrayToTable(in_names);

	SELECT region_tree_root_sid
	  INTO v_region_root
	   FROM csr.region_tree
	 WHERE is_primary = 1;

	OPEN out_cur FOR
		SELECT r.region_sid
		  FROM (
		  	SELECT region_sid, description
		  	  FROM csr.v$region
		  	 WHERE active = 1
		  		START WITH region_sid = v_region_root
		 		CONNECT BY PRIOR region_sid = parent_sid
		  ) r, TABLE(v_table) t
		 WHERE LOWER(r.description) = LOWER(t.value);
END;

PROCEDURE SetTaskPeriods(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_start_dtms		IN	task_pkg.T_DATES,
	in_status_ids		IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_means_task_status_id	task_status.task_status_id%TYPE;
	v_means_completed		task_status.means_completed%TYPE;
	v_means_terminated		task_status.means_terminated%TYPE;
BEGIN
	v_means_completed := 0;
	v_means_terminated := 0;

	-- We assume that all 'arrays' have the same length so we
	-- can perform checks like this on just one of them
	IF (in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL)) THEN
		RETURN;
	END IF;

	-- This will insert into the temp table progress_data
	-- Note: The ind_sid column is used as the status_id
	task_pkg.SetTaskPeriodsFromUI(in_task_sid, in_region_sids, in_start_dtms, in_status_ids);

	-- Uset to fire an alert for that final 'resting status'
	v_means_task_status_id := NULL;

	-- Find the last period status that was inserted
	FOR r IN (
		SELECT means_task_status_id
		  FROM task_period_status tps, (
		  	SELECT period_start_dtm, MAX(period_start_dtm) OVER () max_period_start_dtm, ind_sid task_period_status_id
		  	  FROM progress_data
		  ) x
		 WHERE x.period_start_dtm = x.max_period_start_dtm
		   AND tps.task_period_status_id = x.task_period_status_id
	) LOOP
		-- If the period status mean a task status transition do that now
		IF r.means_task_status_id IS NOT NULL THEN
			SetStatus(in_task_sid, r.means_task_status_id, 'Task status changed by setting task period');
			v_means_task_status_id := r.means_task_status_id;
		END IF;
	END LOOP;

	-- Check to see if the end date needs extending
	CheckExtendInitiative(in_task_sid);

	-- Return an alert id if appropriate
	OPEN out_cur FOR
		SELECT tr.alert_type_id
		  FROM task t, task_status_transition tr
		 WHERE t.task_sid = in_task_sid
		   AND tr.task_status_transition_id = t.last_transition_id
		   AND tr.to_task_status_id = v_means_task_status_id; -- Ensure no match if status was not changed (v_means_task_status_id will be NULL)
END;

PROCEDURE SetMetricValues(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task.start_dtm%TYPE,
	in_end_dtm					IN	task.start_dtm%TYPE,
	in_static_ids				IN	security_pkg.T_SID_IDS,
	in_static_vals				IN	T_VALUES,
	in_static_uoms				IN	security_pkg.T_SID_IDS
)
AS
	v_no_periods				NUMBER;
	v_region_count				NUMBER;
	v_start_dtm					task.start_dtm%TYPE;
	v_end_dtm					task.end_dtm%TYPE;
	v_ind_sid					security_pkg.T_SID_ID;
	v_val_id					csr.val.val_id%TYPE;
	v_period_value				csr.val.val_number%TYPE;
	v_period_dtm 				DATE;
	v_aggregate					ind_template.aggregate%TYPE;
	v_divisibility				ind_template.divisibility%TYPE;
	v_per_period_duration		ind_template.per_period_duration%TYPE;
	v_is_ongoing				ind_template.is_ongoing%TYPE;
	v_one_off_nth_period		ind_template.one_off_nth_period%TYPE;
	v_ongoing_end_dtm			task_ind_template_instance.ongoing_end_dtm%TYPE;
	v_task_period_duration		task.period_duration%TYPE;
	t_static_ids				security.T_SID_TABLE;
BEGIN
	v_start_dtm := TRUNC(in_start_dtm, 'MONTH');
	v_end_dtm := TRUNC(in_end_dtm, 'MONTH');

	-- Get the task's period duration
	SELECT period_duration
	  INTO v_task_period_duration
	  FROM task
	 WHERE task_sid = in_task_sid;

	-- Compute the number of periods in the project
	SELECT MONTHS_BETWEEN(in_end_dtm, in_start_dtm) / v_task_period_duration
	  INTO v_no_periods
	  FROM DUAL;

	-- Count the number of regions this initiative is associated with
	SELECT COUNT(*)
	  INTO v_region_count
	  FROM task_region
	 WHERE task_sid = in_task_sid;
	
	-- Delete any metric values we currently have that 
	-- are not present int the list of ids provided
	t_static_ids := security_pkg.SidArrayToTable(in_static_ids);
	FOR r IN (
		SELECT from_ind_template_id ind_template_id
		  FROM task_ind_template_instance
		 WHERE task_sid = in_task_sid
		   AND val IS NOT NULL
		MINUS
		SELECT column_value ind_template_id
		  FROM TABLE(t_static_ids)
	) LOOP
		-- Remove value from instance table
		UPDATE task_ind_template_instance
		   SET val = NULL,
		   	   entry_val = NULL,
		   	   entry_measure_conversion_id = NULL
		 WHERE task_sid = in_task_sid
		   AND from_ind_template_id = r.ind_template_id;
		-- Delete values from main system
		FOR v IN (
			SELECT v.val_id
			  FROM task_ind_template_instance inst, task_region tr, csr.val v
			 WHERE inst.task_sid = in_task_sid
			   AND inst.from_ind_template_id = r.ind_template_id
			   AND tr.task_sid = tr.task_sid
			   AND v.ind_sid = inst.ind_sid
			   AND v.region_sid = tr.region_sid
		) LOOP
			csr.indicator_pkg.DeleteVal(security_pkg.getACT, v.val_id, 'Initiative data removed');
		END LOOP;  
	END LOOP;
	
	-- Any data to add?
	IF (in_static_ids.COUNT = 0 OR (in_static_ids.COUNT = 1 AND in_static_ids(1) IS NULL)) THEN
		RETURN; -- No, nothing more to do
	END IF;
	
	-- Set values for static metrics if available
	FOR r IN (
		SELECT region_sid
		  FROM task_region
		 WHERE task_sid = in_task_sid
	) LOOP
		FOR i IN in_static_ids.FIRST .. in_static_ids.LAST
		LOOP
			BEGIN
				-- Get the ind sid and some information from ind_template
				-- If the id represents some form of calculation then no data will 
				-- be found, this exception is dealt with at the bottom of this loop
				SELECT ti.ind_sid, t.aggregate, t.divisibility, per_period_duration, is_ongoing, one_off_nth_period, ongoing_end_dtm
				  INTO v_ind_sid, v_aggregate, v_divisibility, v_per_period_duration, v_is_ongoing, v_one_off_nth_period, v_ongoing_end_dtm
				  FROM task_ind_template_instance ti, ind_template t
				 WHERE t.ind_template_id = in_static_ids(i)
				   AND ti.from_ind_template_id = t.ind_template_id
				   AND ti.task_sid = in_task_sid
				   AND t.calculation IS NULL -- We don't set values for calculation indicators
				   AND t.is_npv = 0;		 -- We don't set values for npv indicators (as they are also calculations)

				-- Delete any old data before inserting the new data
				FOR v IN (
					SELECT val_id
					  FROM csr.val
					 WHERE region_sid = r.region_sid
					   AND ind_sid = v_ind_sid
				) LOOP
					csr.indicator_pkg.DeleteVal(security_pkg.getACT, v.val_id,
						'Initiative data saved, removing old values');
				END LOOP;

				-- Reset the start/end dtms
				v_start_dtm := TRUNC(in_start_dtm, 'MONTH');
				v_end_dtm := TRUNC(in_end_dtm, 'MONTH');

				-- Compute the per month value for the metric
				-- ...
				IF v_divisibility != csr.csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					-- Not divisible, don't divide at all
					v_period_value := in_static_vals(i);
					
				ELSIF v_one_off_nth_period IS NOT NULL THEN
					-- nth period value is stored undivided by period in the specified period
					v_period_value := in_static_vals(i);
					
				ELSIF v_per_period_duration IS NOT NULL THEN
					-- Divide by the period
					v_period_value := in_static_vals(i) * v_task_period_duration / v_per_period_duration;
					
				ELSE
					-- Just divide by the number of months in the project
					v_period_value := in_static_vals(i) / v_no_periods;
					
				END IF;
				
				-- Ongoing savings occur after the project finishes
				IF v_is_ongoing <> 0 THEN
					--modify the start and end dates
					v_start_dtm := TRUNC(in_end_dtm, 'MONTH');
					v_end_dtm := TRUNC(v_ongoing_end_dtm, 'MONTH');
					
				END IF;

				-- Put the entered values into the template instance table
				UPDATE task_ind_template_instance
				   SET val = csr.measure_pkg.UNSEC_GetBaseValue(in_static_vals(i), in_static_uoms(i), v_start_dtm),
				   	   entry_val = in_static_vals(i),
				   	   entry_measure_conversion_id = DECODE(in_static_uoms(i), -1, NULL, in_static_uoms(i))
				 WHERE task_sid = in_task_sid
				   AND from_ind_template_id = in_static_ids(i);

				-- Divide the period value between the regions (only if divisible)
				IF v_divisibility = csr.csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_period_value := v_period_value / v_region_count;
				END IF;

				-- If we're dealing with a one off nth period, then set the start date to that period, 
				-- the loop below will set the value for that period and exit immediately
				v_period_dtm :=
					CASE WHEN v_one_off_nth_period IS NOT NULL THEN 
						ADD_MONTHS(v_start_dtm, v_one_off_nth_period * v_task_period_duration)
					ELSE 
						v_start_dtm 
					END;
				
				-- Loop over periods inserting values
				LOOP
					csr.indicator_pkg.SetValue(
						security_pkg.GetAct,
						v_ind_sid,
						r.region_sid,
						v_period_dtm,
						ADD_MONTHS(v_period_dtm, v_task_period_duration),
						csr.measure_pkg.UNSEC_GetBaseValue(v_period_value, in_static_uoms(i), v_period_dtm),
						0,
						csr.csr_data_pkg.SOURCE_TYPE_DIRECT,
						NULL,
						CASE WHEN in_static_uoms(i) = -1 THEN NULL ELSE in_static_uoms(i) END,
						CASE WHEN in_static_uoms(i) = -1 THEN NULL ELSE v_period_value END,
						0,
						NULL,
						v_val_id
					);

					-- If we're dealing with a one off nth period then exit now
					EXIT WHEN v_one_off_nth_period IS NOT NULL;
					
					-- move to next period
					v_period_dtm := ADD_MONTHS(v_period_dtm, v_task_period_duration);
					EXIT WHEN v_period_dtm >= v_end_dtm;
				END LOOP;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- The indicator template was some sort of calculation - ignore.
			END;
		END LOOP;
	END LOOP;
	
	-- Run calculation helpers
	FOR r IN (
		SELECT it.ind_template_id, EXTRACTVALUE(VALUE(x), '//helper/text()') helper
	      FROM task_ind_template_instance inst, ind_template it, TABLE(XMLSEQUENCE(EXTRACT(it.calculation, '//helper'))) x
	     WHERE inst.task_sid = in_task_sid
	       AND it.ind_template_id = inst.from_ind_template_id
	) LOOP
		EXECUTE IMMEDIATE 'BEGIN '||r.helper||'(:1,:2);END;'
			USING in_task_sid, r.ind_template_id;
	END LOOP;
END;

PROCEDURE MoveEndDtm(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_new_end_dtm				IN	task.end_dtm%TYPE
)
AS
	v_start_dtm					task.start_dtm%TYPE;
	v_end_dtm					task.start_dtm%TYPE;
	v_static_ids				security_pkg.T_SID_IDS;
	v_static_vals				T_VALUES;
	v_static_uoms				security_pkg.T_SID_IDS;
BEGIN
	-- If the end dtm changes then the metric values need to be re-spread
	-- ...

	SELECT start_dtm, NVL(in_new_end_dtm, end_dtm)
	  INTO v_Start_dtm, v_end_dtm
	  FROM task t
	 WHERE t.task_sid = in_task_sid;

	-- Build a set of arguments for SetMetricValues based on existing data
	FOR r IN (
		SELECT it.ind_template_id, inst.entry_measure_conversion_id, NVL(inst.entry_val, inst.val) val
          FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst
         WHERE it.ind_template_id = pit.ind_template_id
           AND it.calculation IS NULL
           AND it.is_npv = 0
           AND pit.project_sid = t.project_sid
           AND pit.update_per_period = 0
		   AND inst.from_ind_template_id = it.ind_template_id
		   AND t.task_sid = in_task_sid
		   AND t.task_sid = inst.task_sid
	) LOOP
		v_static_ids(v_static_ids.COUNT + 1) := r.ind_template_id;
		v_static_vals(v_static_vals.COUNT + 1) := r.val;
		v_static_uoms(v_static_uoms.COUNT + 1) := NVL(r.entry_measure_conversion_id, -1);
	END LOOP;

	 -- Re-set the static metric values
	 SetInitiativeImpl(
		in_task_sid,
		v_start_dtm,
		v_end_dtm,
		v_static_ids,
		v_static_vals,
		v_static_uoms
	);
END;

PROCEDURE CompleteInitiative(
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
	v_auto_date			NUMBER(1);
	v_start_dtm			task.start_dtm%TYPE;
	v_old_end_dtm		task.end_dtm%TYPE;
	v_new_end_dtm		task.end_dtm%TYPE;
BEGIN
	SELECT auto_complete_date
	  INTO v_auto_date
	  FROM customer_options
	 WHERE app_sid = security_pkg.GetAPP;
	
	IF v_auto_date = 1 THEN
		-- Complete as of the last task period status dtm
		SELECT start_dtm, end_dtm, ADD_MONTHS(TRUNC(NVL(last_task_period_dtm, SYSDATE), 'MONTH'), period_duration)
		  INTO v_start_dtm, v_old_end_dtm, v_new_end_dtm
		  FROM task
		 WHERE task_sid = in_task_sid;
	
		IF v_old_end_dtm <> v_new_end_dtm THEN
			MoveEndDtm(in_task_sid, v_new_end_dtm);
		END IF;
	END IF;
END;

PROCEDURE TerminateInitiative(
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CompleteInitiative(in_task_sid);

	-- Delete any ongoing savings
	-- Delete metric data from main system
	FOR r IN (
		SELECT ti.ind_sid, tr.region_sid
		  FROM task_ind_template_instance ti, task_region tr, ind_template it
		 WHERE ti.task_sid = in_task_sid
		   AND tr.task_sid = ti.task_sid
		   AND it.ind_template_id = ti.from_ind_template_id
		   AND it.is_ongoing = 1
	) LOOP
		FOR v IN (
			SELECT val_id
			  FROM csr.val
			 WHERE region_sid = r.region_sid
			   AND ind_sid = r.ind_sid
		) LOOP
			csr.indicator_pkg.DeleteVal(security_pkg.GetAct, v.val_id,
				'Ongoing metric data deleted by initiatives due to initiative termination');
		END LOOP;
	END LOOP;
END;

PROCEDURE CheckExtendInitiative(
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
	v_start_dtm			task.start_dtm%TYPE;
	v_end_dtm			task.end_dtm%TYPE;
	v_period_duration	task.period_duration%TYPE;
	v_finished			BOOLEAN;
BEGIN
	-- If the task period status is set for the final period and that
	-- status does not mean terminated or completed then extend the end date

	v_end_dtm := NULL;
	v_finished := FALSE;

	-- Multiple regions possible
	FOR r IN (
		SELECT t.end_dtm, t.period_duration, ts.means_terminated, ts.means_completed
		  FROM task t, task_period tp, task_period_status tps, task_status ts
		 WHERE t.task_sid = in_task_sid
		   AND tp.task_sid = t.task_sid
		   AND tp.end_dtm = t.end_dtm
		   AND tps.task_period_status_id = tp.task_period_status_id
		   AND ts.task_status_id(+) = tps.means_task_status_id
	) LOOP
		-- Any result from this query indicates that the ast pask period is set
		v_end_dtm := r.end_dtm;
		v_period_duration := r.period_duration;
		IF r.means_terminated = 1 OR r.means_completed = 1 THEN
			v_finished := TRUE;
		END IF;
	END LOOP;

	-- The end dtm is only set if the last period was set
	IF v_end_dtm IS NOT NULL AND NOT v_finished THEN
		-- Enxtend the end date by one period duration
		MoveEndDtm(in_task_sid, ADD_MONTHS (v_end_dtm, v_period_duration));
	END IF;
END;

-------------------------------

PROCEDURE GetInitiativeValExport(
	out_project					OUT	SYS_REFCURSOR,
	out_data					OUT	SYS_REFCURSOR,
	out_team					OUT	SYS_REFCURSOR,
	out_sponsors				OUT	SYS_REFCURSOR,
	out_tags					OUT	SYS_REFCURSOR
)
AS
	v_class_id					security_pkg.T_CLASS_ID;
BEGIN
	-- Note, we'll need to map these in the c#
	OPEN out_project FOR
		SELECT project_sid, task_fields_xml
		  FROM project
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_team FOR
		SELECT t.task_sid, t.internal_ref task_name, i.name, i.email
		  FROM initiative_project_team i, v$user_initiatives t
		 WHERE i.task_sid = t.task_sid;

	OPEN out_sponsors FOR
		SELECT t.task_sid, t.internal_ref task_name, i.name, i.email
		  FROM initiative_sponsor i, v$user_initiatives t
		 WHERE i.task_sid = t.task_sid;

	OPEN out_tags FOR
		SELECT t.task_sid, tg.tag_group_id, tg.name, tg.label, csr.stragg(tag.tag) agg_members
		  FROM v$user_initiatives t, task_tag tt, tag_group tg, tag_group_member tgm, tag
		 WHERE tt.task_sid = t.task_sid
		   AND tag.tag_id = tt.tag_id
		   AND tgm.tag_group_id = tg.tag_group_id
		   AND tgm.is_visible <> 0
		   AND tag.tag_id = tgm.tag_id
		 GROUP BY t.task_sid, tg.tag_group_id, tg.name, tg.label;

	-- We need to know the class id for 'CSRUserGroup'
	v_class_id := class_pkg.GetClassID('CSRUserGroup');

	-- Select the initiative metric data
	OPEN out_data FOR
		SELECT /*+ALL_ROWS*/
			init.task_sid, init.initiative_name, init.initiative_reference, init.initiative_start_dtm, init.initiative_end_dtm,
		    init.project_sid, init.initiative_type,
		    init.owner_name, init.owner_groups, init.owners_region_sids, init.owners_region_desc,
		    init.region_sid, init.region_desc region_or_property,
		    --
		    flds.fields_xml, -- we get description and other stuff from here
		    --
		    static.name static_metric_name,
		    static.description static_metric_desc,
		    static.val static_metric_val,
		    --
		    periodic.name periodic_metric_name,
		    periodic.description periodic_metric_desc,
		    periodic.ind_sid periodic_metric_ind_sid,
		    periodic.region_sid periodic_metric_region_sid,
		    periodic.period_start_dtm periodic_metric_start_dtm,
		    periodic.val periodic_metric_val,
		    periodic.metric_key
	  FROM (
		SELECT t.task_sid, t.name initiative_name, t.internal_ref initiative_reference, t.start_dtm initiative_start_dtm, t.end_dtm initiative_end_dtm,
	        p.project_sid, p.name initiative_type,
	        t.owner_sid, usr.full_name owner_name,
			csr.stragg3(rmount.region_sid) owners_region_sids,
			csr.stragg3(rmount.description) owners_region_desc,
	        rgn.region_sid, rgn.description region_desc,
	        csr.stragg3(gobj.name) owner_groups
	      FROM
	          v$user_initiatives t, project p, csr.v$region rgn,
	          csr.csr_user usr, csr.region_start_point rsp, csr.v$region rmount,
			  security.group_members gmbr, security.securable_object gobj
	      	--
	     WHERE p.project_sid = t.project_sid
	       AND rgn.region_sid = t.region_sid
	       --
	       AND usr.app_sid = p.app_sid
	       AND usr.csr_user_sid = t.owner_sid
		   AND rsp.user_sid(+) = usr.csr_user_sid
	       AND rmount.region_sid(+) = rsp.region_sid
	       --
	       AND gmbr.member_sid_id = t.owner_sid
	       AND gobj.sid_id(+) = gmbr.group_sid_id
	       AND gobj.class_id(+) = v_class_id
	       AND gobj.application_sid_id(+) = SYS_CONTEXT('SECURITY', 'APP')
		 GROUP BY t.task_sid, t.name, t.internal_ref, t.start_dtm, t.end_dtm,
		          p.project_sid, p.name,
		          t.owner_sid, usr.full_name, rmount.region_sid, rmount.description,
		          rgn.region_sid, rgn.description
		) init, (
		    SELECT t.task_sid, it.name, it.description, inst.ind_sid, inst.val
	          FROM v$user_initiatives t, ind_template it, project_ind_template pit, task_ind_template_instance inst
	         WHERE it.ind_template_id = pit.ind_template_id
	           AND pit.project_sid = t.project_sid
	           AND pit.update_per_period = 0
			   AND inst.from_ind_template_id = it.ind_template_id
			   AND t.task_sid = inst.task_sid
		) static, (
		    SELECT t.task_sid, t.name, t.description, t.ind_sid, t.region_sid, v.period_start_dtm,
		        v.val_number val,
		        ROWNUM metric_key
		      FROM (
		        SELECT t.task_sid, it.name, it.description, inst.ind_sid, t.region_sid, t.start_dtm
		          FROM v$user_initiatives t, ind_template it, project_ind_template pit, task_ind_template_instance inst
		         WHERE it.ind_template_id = pit.ind_template_id
		           AND pit.update_per_period = 1
		           AND pit.project_sid = t.project_sid
		           AND inst.from_ind_template_id = it.ind_template_id
		           AND t.task_sid = inst.task_sid
		         UNION ALL
		          SELECT t.task_sid, 'progress' name, 'Progress' description, t.output_ind_sid ind_sid, t.region_sid, t.start_dtm
		            FROM v$user_initiatives t, task_region tr, initiative_properties ip
		        ) t, csr.val v
		     WHERE v.ind_sid = t.ind_sid
		       AND v.region_sid = t.region_sid
		       AND v.period_start_dtm >= t.start_dtm
		) periodic, task flds
		WHERE periodic.region_sid = init.region_sid
		  AND init.task_sid = static.task_sid
		  AND init.task_sid = periodic.task_sid
		  AND flds.task_sid = init.task_sid
		ORDER BY periodic.metric_key, task_sid;
END;

PROCEDURE GetProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT project_sid, name, app_sid, max_period_duration, start_dtm, end_dtm, task_fields_xml, task_period_fields_xml, icon, pos_group, pos,
			security_pkg.SQL_IsAccessAllowedSID(in_act_id, project_sid, security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			security_pkg.SQL_IsAccessAllowedSID(in_act_id, project_sid, security_pkg.PERMISSION_WRITE) can_edit
		  FROM project
		 WHERE app_sid = in_app_sid
		   AND is_initiatives = 1
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, project_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY pos_group, pos, name;
END;

PROCEDURE GetInitiativesAtLevel(
	in_project_sid		IN	security_pkg.T_SID_ID,
	in_level			IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_project_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read project with sid ' || in_project_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT task_sid sid, name description
		  FROM (
		  	SELECT LEVEL lvl, task_sid, name
		  	  FROM task
		  	 WHERE project_sid = in_project_sid
		  	 	START WITH parent_task_sid IS NULL
		  	 	CONNECT BY PRIOR task_sid = parent_task_sid
		) x
		 WHERE x.lvl = in_level
		 ORDER BY description;
END;

PROCEDURE AddComment(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment_text				IN	task_comment.comment_text%TYPE
)
AS
	v_comment_id				task_comment.task_comment_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_task_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing task with sid ' || in_task_sid);
	END IF;
	
	IF LENGTH(in_comment_text) > 0 THEN
		task_pkg.AddComment(security_pkg.GetACT, in_task_sid, in_comment_text, v_comment_id);
	END IF;
END;

PROCEDURE GetHistroyAndComments (
	in_task_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid '||in_task_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT x.task_sid, x.dtm set_dtm, x.comment_text, x.task_status_id, x.task_status_label, x.user_sid, u.full_name
		  FROM csr.csr_user u, (
			SELECT h.task_sid, h.set_dtm dtm, h.set_by_user_sid user_sid, h.comment_text, h.task_status_id, ts.label task_status_label
			  FROM task_status_history h, task_status ts
			 WHERE h.task_sid = in_task_sid
			   AND ts.task_status_id = h.task_status_id
			UNION ALL
			SELECT task_sid, posted_dtm dtm, user_sid, comment_text, NULL task_status_id, NULL task_status_label
			  FROM task_comment
			 WHERE task_sid = in_task_sid
		 ) x
		 WHERE u.csr_user_sid = x.user_sid
		 ORDER BY x.dtm DESC;
END;

PROCEDURE BarclaysEnergyPayback (
	in_task_sid			security_pkg.T_SID_ID,
	in_template_id		ind_template.ind_template_id%TYPE
)
AS
	v_val_id			csr.val.val_id%TYPE;
	v_num				NUMBER(24,10);
	v_den				NUMBER(24,10);
	v_val				NUMBER(24,10);
	v_csav				NUMBER(24,10);
	v_ocsav				NUMBER(24,10);
BEGIN
	FOR r IN (
		SELECT t.task_sid, tr.region_sid, inst.ind_sid, 
			t.start_dtm, t.end_dtm, inst.ongoing_end_dtm,
			i_capex.val val_capex,
			i_revex.val val_revex,
			i_orevex.val val_orevex,
			i_opex.val val_opex
		  FROM task t, task_region tr,
		  	task_ind_template_instance inst,
		  	task_ind_template_instance i_capex, ind_template it_capex,
		  	task_ind_template_instance i_revex, ind_template it_revex,
		  	task_ind_template_instance i_orevex, ind_template it_orevex,
		  	task_ind_template_instance i_opex, ind_template it_opex
		 WHERE t.task_sid = in_task_sid
		   AND tr.task_sid = t.task_sid
		   AND inst.task_sid = t.task_sid
		   AND inst.from_ind_template_id = in_template_id
		   AND i_capex.task_sid = t.task_sid
		   AND it_capex.ind_template_id = i_capex.from_ind_template_id
		   AND it_capex.name = 'capex_total'
		   AND i_revex.task_sid = t.task_sid
		   AND it_revex.ind_template_id = i_revex.from_ind_template_id
		   AND it_revex.name = 'revex_costs'
		   AND i_orevex.task_sid = t.task_sid
		   AND it_orevex.ind_template_id = i_orevex.from_ind_template_id
		   AND it_orevex.name = 'revex_costs_ong'
		   AND i_opex.task_sid = t.task_sid
		   AND it_opex.ind_template_id = i_opex.from_ind_template_id
		   AND it_opex.name = 'opex_sav_ong'
	) LOOP
		-- We need to compute the energy cost saving 
		-- values from the val table (stored calcs)
		SELECT SUM(val_number)
		  INTO v_csav
		  FROM csr.val
		 WHERE period_start_dtm >= r.start_dtm
		   AND period_end_dtm < r.end_dtm
		   AND source_type_id = csr.csr_data_pkg.SOURCE_TYPE_STORED_CALC
		   AND region_sid = r.region_sid
		   AND ind_sid = (
		   		SELECT ind_sid
		   		  FROM ind_template it, task_ind_template_instance inst
		   		 WHERE it.name = 'calc_energy_cost'
		   		   AND inst.from_ind_template_id = it.ind_template_id
		   		   AND inst.task_sid = r.task_sid
		   );
		   
		SELECT SUM(val_number)
		  INTO v_ocsav
		  FROM csr.val
		 WHERE period_start_dtm >= r.end_dtm
		   AND period_end_dtm < r.ongoing_end_dtm
		   AND source_type_id = csr.csr_data_pkg.SOURCE_TYPE_STORED_CALC
		   AND region_sid = r.region_sid
		   AND ind_sid = (
		   		SELECT ind_sid
		   		  FROM ind_template it, task_ind_template_instance inst
		   		 WHERE it.name = 'calc_energy_cost_ong'
		   		   AND inst.from_ind_template_id = it.ind_template_id
		   		   AND inst.task_sid = r.task_sid
		   );
		
		v_num := NVL(r.val_capex, 0) + NVL(r.val_revex, 0) - NVL(v_csav, 0);
		v_den := NVL(v_ocsav, 0) + NVL(r.val_opex, 0) - NVL(r.val_orevex, 0);
		v_val := NULL;
		
		security_pkg.debugmsg('v_num = '||v_num);
		security_pkg.debugmsg('v_den = '||v_den);
		
		IF v_num IS NOT NULL AND v_den IS NOT NULL AND v_den != 0 THEN
			v_val := v_num / (v_den * 12);
		END IF;	
		
		csr.indicator_pkg.SetValue(
			in_act_id			=> security_pkg.GetACT,
			in_ind_sid			=> r.ind_sid,
			in_region_sid		=> r.region_sid,
			in_period_start		=> r.start_dtm,
			in_period_end		=> r.ongoing_end_dtm,
			in_val_number		=> v_val,
			in_flags			=> 0,
			in_note				=> NULL,
			out_val_id			=> v_val_id
		);
	END LOOP;
END;

PROCEDURE BarclaysOtherPayback (
	in_task_sid			security_pkg.T_SID_ID,
	in_template_id		ind_template.ind_template_id%TYPE
)
AS
	v_val_id			csr.val.val_id%TYPE;
	v_num				NUMBER(24,10);
	v_den				NUMBER(24,10);
	v_val				NUMBER(24,10);
BEGIN
	FOR r IN (
		SELECT t.task_sid, tr.region_sid, inst.ind_sid, 
			t.start_dtm, inst.ongoing_end_dtm, 
			i_capex.val val_capex,
			i_revex.val val_revex,
			i_csav.val val_csav, 
			i_ocsav.val val_ocsav,
			i_orevex.val val_orevex
		  FROM task t, task_region tr,
		  	task_ind_template_instance inst,
		  	task_ind_template_instance i_capex, ind_template it_capex,
		  	task_ind_template_instance i_revex, ind_template it_revex,
		  	task_ind_template_instance i_csav, ind_template it_csav,
		  	task_ind_template_instance i_ocsav, ind_template it_ocsav,
		  	task_ind_template_instance i_orevex, ind_template it_orevex
		 WHERE t.task_sid = in_task_sid
		   AND tr.task_sid = t.task_sid
		   AND inst.task_sid = t.task_sid
		   AND inst.from_ind_template_id = in_template_id
		   AND i_capex.task_sid = t.task_sid
		   AND it_capex.ind_template_id = i_capex.from_ind_template_id
		   AND it_capex.name = 'capex_total'
		   AND i_revex.task_sid = t.task_sid
		   AND it_revex.ind_template_id = i_revex.from_ind_template_id
		   AND it_revex.name = 'revex_costs'
		   AND i_csav.task_sid = t.task_sid
		   AND it_csav.ind_template_id = i_csav.from_ind_template_id
		   AND it_csav.name = 'cost_sav'
		   AND i_orevex.task_sid = t.task_sid
		   AND it_orevex.ind_template_id = i_orevex.from_ind_template_id
		   AND it_orevex.name = 'revex_costs_ong'
		   AND i_ocsav.task_sid = t.task_sid
		   AND it_ocsav.ind_template_id = i_ocsav.from_ind_template_id
		   AND it_ocsav.name = 'cost_sav_ong'
	) LOOP
		v_num := NVL(r.val_capex, 0) + NVL(r.val_revex, 0) - NVL(r.val_csav, 0);
		v_den := NVL(r.val_ocsav, 0) - NVL(r.val_orevex, 0);
		v_val := NULL;
		
		IF v_num IS NOT NULL AND v_den IS NOT NULL AND v_den != 0 THEN
			v_val := v_num / (v_den * 12);
		END IF;	
		
		csr.indicator_pkg.SetValue(
			in_act_id			=> security_pkg.GetACT,
			in_ind_sid			=> r.ind_sid,
			in_region_sid		=> r.region_sid,
			in_period_start		=> r.start_dtm,
			in_period_end		=> r.ongoing_end_dtm,
			in_val_number		=> v_val,
			in_flags			=> 0,
			in_note				=> NULL,
			out_val_id			=> v_val_id
		);
	END LOOP;
END;

PROCEDURE RenameInitiative (
	in_project_sid		IN	security_pkg.T_SID_ID,
	in_old_name			IN	task.name%TYPE,
	in_new_name			IN	task.name%TYPE
)
AS
	v_task_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT task_sid
	  INTO v_task_sid
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND project_sid = in_project_sid
	   AND name = in_old_name;
	   
	RenameInitiative(v_task_sid, in_new_name);
END;

PROCEDURE RenameInitiative (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	task.name%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied renaming initiative with sid '||in_task_sid);
	END IF;
	
	-- Rename the task
	UPDATE task
	   SET name = in_name
	 WHERE task_sid = in_task_sid;
	
	-- Rename metric indicators
	INTERNAL_RefreshMetricNames(in_task_sid);
END;

PROCEDURE GetProjectTeam (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name, email
		  FROM initiative_project_team
		 WHERE task_sid = in_task_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, task_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetProjectSponsor (
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name, email
		  FROM initiative_sponsor
		 WHERE task_sid = in_task_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, task_sid, security_pkg.PERMISSION_READ) = 1;
END;

END initiative_pkg;
/
