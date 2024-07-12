CREATE OR REPLACE PACKAGE BODY ACTIONS.ind_template_pkg
IS

PROCEDURE INTERNAL_CreateGasInds (
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
	v_factor_type_id		ind_template.factor_type_id%TYPE;
	v_gas_measure_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT factor_type_id, gas_measure_sid
		  INTO v_factor_type_id, v_gas_measure_sid
		  FROM ind_template it, task_ind_template_instance inst
		 WHERE inst.ind_sid = in_ind_sid
		   AND it.ind_template_id = inst.from_ind_template_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			BEGIN
				SELECT factor_type_id, gas_measure_sid
				  INTO v_factor_type_id, v_gas_measure_sid
				  FROM ind_template it, project_ind_template_instance inst
				 WHERE inst.ind_sid = in_ind_sid
				   AND it.ind_template_id = inst.from_ind_template_id;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT factor_type_id, gas_measure_sid
						  INTO v_factor_type_id, v_gas_measure_sid
						  FROM ind_template it, root_ind_template_instance inst
						 WHERE inst.ind_sid = in_ind_sid
						   AND it.ind_template_id = inst.from_ind_template_id;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							v_factor_type_id := NULL;
					   		v_gas_measure_sid := NULL;
					END;
			END;
	END;
	
	IF v_factor_type_id IS NOT NULL AND
	   v_gas_measure_sid IS NOT NULL THEN
	   	
		-- Create the gas indicators
		csr.indicator_pkg.CreateGasIndicators(in_ind_sid);
		
		-- store gas ind sids against the template instance
		INSERT INTO instance_gas_ind
			(task_sid, from_ind_template_id, ind_sid, gas_metric_id)
			SELECT inst.task_sid, inst.from_ind_template_id, i.ind_sid, ind_template_id_seq.NEXTVAL
			  FROM csr.ind i, csr.gas_type gt, task_ind_template_instance inst
			 WHERE i.map_to_ind_sid = in_ind_sid
			   AND i.gas_type_id = gt.gas_type_id
			   AND inst.ind_sid = in_ind_sid;
	END IF;
END;

PROCEDURE INTERNAL_DeleteGasInds (
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Delete the gas indicators
	FOR r IN (
		SELECT ind_sid 
		  FROM csr.ind 
		 WHERE map_to_ind_sid = in_ind_sid
	) LOOP
		DELETE FROM instance_gas_ind
		 WHERE ind_sid = r.ind_sid;
		securableobject_pkg.DeleteSO(security_pkg.GetACT, r.ind_sid);
	END LOOP;
END;

PROCEDURE CreateIndicator(
	in_template_name		IN	ind_template.name%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_name					IN	csr.ind_description.description%TYPE,
	out_ind_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_template_id			ind_template.ind_template_id%TYPE;
BEGIN
	SELECT ind_template_id
	  INTO v_template_id
	  FROM ind_template
	 WHERE app_sid = security_pkg.GetApp
	   AND name = in_template_name;

	CreateIndicator(v_template_id, in_parent_ind_sid, in_start_dtm, in_name, out_ind_sid);
END;

PROCEDURE CreateIndicator(
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_name					IN	csr.ind_description.description%TYPE,
	out_ind_sid				OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	CreateIndicator(
		in_template_id,
		in_parent_ind_sid,
		in_start_dtm,
		in_name,
		NULL,
		out_ind_sid
	);
END;

PROCEDURE CreateIndicator(
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DATE,
	in_name					IN	csr.ind_description.description%TYPE,
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_ind_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_row					ind_template%ROWTYPE;
	v_parent_ind_sid		security_pkg.T_SID_ID;
	v_ind_name				ind_template.name%TYPE;
	v_ind_desc				ind_template.description%TYPE;
BEGIN
	-- If parent ind sid is null then create under the actions root indicator
	v_parent_ind_sid := in_parent_ind_sid;
	IF v_parent_ind_sid IS NULL THEN
		v_parent_ind_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Indicators/Actions');
	END IF;

	-- If the name is null then use the name/description from the ind template
	IF in_name IS NULL THEN
		SELECT name, description
		  INTO v_ind_name, v_ind_desc
		  FROM ind_template
		 WHERE ind_template_id = in_template_id;
	ELSE
		v_ind_name := SUBSTR(in_name, 0, 255);
		v_ind_desc := in_name;
	END IF;

	-- Select the template row
	SELECT *
	  INTO v_row
	  FROM ind_template
	 WHERE ind_template_id = in_template_id;

	-- TODO: bit cack - it truncates the name -> scope for duplicate objects
	csr.indicator_pkg.CreateIndicator(
		in_act_id				=> security_pkg.GetAct, 
		in_parent_sid_id		=> v_parent_ind_sid, 
		in_app_sid				=> security_pkg.GetApp,
		in_name					=> v_ind_name,
		in_description			=> v_ind_desc,
		in_measure_sid			=> v_row.measure_sid,
		in_multiplier			=> 1,
		in_scale				=> 0,
		in_format_mask			=> v_row.format_mask,
		in_target_direction		=> v_row.target_direction,
		in_info_xml				=> v_row.info_xml,
		in_divisibility			=> v_row.divisibility,
		in_start_month			=> EXTRACT(MONTH FROM in_start_dtm),
		in_aggregate			=> v_row.aggregate,
		in_core					=> 0,
		in_is_gas_ind			=> 0, -- Even if this is a gas ind, defer creation of gas inds
		in_factor_type_id		=> v_row.factor_type_id,
		in_gas_measure_sid		=> v_row.gas_measure_sid,
		out_sid_id				=> out_ind_sid
	);

	-- If this template contains a calculation then we need to fix-up the
	-- calculation XML with the actual indicator instance sids and also call
	-- AddCalcDependency for the referenced indicators. We need the task sid
	-- to do this so we can pick the sids of the correct instances
	IF in_task_sid IS NOT NULL AND 
	   v_row.calculation IS NOT NULL AND
	   v_row.is_npv = 0 THEN
		ConvertCalculation(in_task_sid, in_template_id, out_ind_sid);
	END IF;
	
	-- NPV calculation
	IF in_task_sid IS NOT NULL AND 
	   v_row.is_npv = 1 THEN
	   	MakeNPV(in_task_sid, in_template_id, out_ind_sid);
	   	NULL;
	 END IF;
END;

-- TODO: 13p fix needed
PROCEDURE ConvertCalculation(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
	v_period_set_id			csr.ind.period_set_id%TYPE;
	v_period_interval_id	csr.ind.period_interval_id%TYPE;
	v_calc_xml				csr.ind.calc_xml%TYPE;
	v_is_stored				NUMBER(1);
	v_replacement_error		VARCHAR2(4000);
BEGIN
	-- Check for helper package
	FOR r IN (
		SELECT EXTRACTVALUE(VALUE(x), '//helper/text()') helper
	      FROM ind_template it, TABLE(XMLSEQUENCE(EXTRACT(it.calculation, '//helper'))) x
	     WHERE it.ind_template_id = in_template_id
	) LOOP
		-- Nothing to do
		--security_pkg.DebugMsg('Helper: '||r.helper);
		RETURN;
	END LOOP;
	
	-- Extract the calculation template xml 
	-- into a temp table for manipulation
	-- XXX: There may be a better way to run the update on the xml 
	-- but I didn't see anything obvious in the documentation
	DELETE FROM temp_calc;
	INSERT INTO temp_calc (xml, stored_calc) (
		SELECT calculation, is_stored_calc
		  FROM ind_template
		 WHERE ind_template_id = in_template_id
	);
	
	-- Loop over any ind templates that are named in the calculation xml 
	-- trying to find the actual indicator instances for this task
	DELETE FROM temp_task_sids;
	FOR r IN (
		SELECT ind_template_id, name, ind_sid
		  FROM task_ind_template_instance inst, ind_template it
		 WHERE inst.task_sid = in_task_sid
		   AND inst.from_ind_template_id = it.ind_template_id
		   AND it.name IN (
		    SELECT EXTRACT(VALUE(x), '//path/@template').getStringVal()
		      FROM ind_template it, TABLE(XMLSEQUENCE(EXTRACT(it.calculation, '//path'))) x
		     WHERE it.ind_template_id = in_template_id
		  )
	) LOOP
		-- Delete any existing sid attribute
		UPDATE temp_calc
		   SET xml = DELETEXML(xml, '//path[@template="'||r.name||'"]/@sid')
		 WHERE EXISTSNODE(xml, '//path[@template="'||r.name||'"]/@sid') = 1;

		-- Insert the ind instance sid
		UPDATE temp_calc
		   SET xml = INSERTCHILDXML(xml, '//path[@template="'||r.name||'"]', '@sid', r.ind_sid);
		
		-- Remove the template attribute
		UPDATE temp_calc
		   SET xml = DELETEXML(xml, '//path[@template="'||r.name||'"]/@template')
		 WHERE EXISTSNODE(xml, '//path[@template="'||r.name||'"]/@template') = 1;
		
		-- Keep track of the ind sids (just use the temp task sids table to stroe the sids)
		INSERT INTO temp_task_sids (task_sid) VALUES (r.ind_sid);
		
	END LOOP;
	
	-- Loop over any indicator lookup keys and insert the actual indicator instance sids
	FOR r IN (
		SELECT i.ind_sid, i.lookup_key
		  FROM csr.ind i, (
			SELECT EXTRACT(VALUE(x), '//path/@lookup').getStringVal() lookup_key
      		  FROM ind_template it, TABLE(XMLSEQUENCE(EXTRACT(it.calculation, '//path'))) x
      		 WHERE it.ind_template_id = in_template_id
	      ) x
	     WHERE i.lookup_key = x.lookup_key
	) LOOP
		
		-- Delete any existing sid attribute
		UPDATE temp_calc
		   SET xml = DELETEXML(xml, '//path[@lookup="'||r.lookup_key||'"]/@sid')
		 WHERE EXISTSNODE(xml, '//path[@lookup="'||r.lookup_key||'"]/@sid') = 1;

		-- Insert the ind instance sid
		UPDATE temp_calc
		   SET xml = INSERTCHILDXML(xml, '//path[@lookup="'||r.lookup_key||'"]', '@sid', r.ind_sid);
		
		-- Remove the lookup attribute
		UPDATE temp_calc
		   SET xml = DELETEXML(xml, '//path[@lookup="'||r.lookup_key||'"]/@lookup')
		 WHERE EXISTSNODE(xml, '//path[@lookup="'||r.lookup_key||'"]/@lookup') = 1;
		
		-- Keep track of the ind sids (just use the temp task sids table to stroe the sids)
		INSERT INTO temp_task_sids (task_sid) VALUES (r.ind_sid);
		
	END LOOP;
	
	-- Check for any path or literal nodes still containing template atributes (i.e. not replaced)
	FOR r IN (
		SELECT tpl
		  FROM (
		  SELECT EXTRACTVALUE(x.column_value, '//path/@template | literal/@template') tpl
		    FROM temp_calc tc, TABLE(XMLSEQUENCE(EXTRACT(tc.xml, '//path | //literal'))) x
		  )
		 WHERE tpl IS NOT NULL
	) LOOP
		v_replacement_error := v_replacement_error || ' template:''' || r.tpl || '''';
	END LOOP;
	 	
	-- Check for any path or literal nodes still containing lookup atributes (i.e. not replaced)
	FOR r IN (
		SELECT lookup
		  FROM (
		  SELECT EXTRACTVALUE(x.column_value, '//path/@lookup | literal/@lookup') lookup
		    FROM temp_calc tc, TABLE(XMLSEQUENCE(EXTRACT(tc.xml, '//path | //literal'))) x
		  )
		 WHERE lookup IS NOT NULL
	) LOOP
		v_replacement_error := v_replacement_error || ' lookup:''' || r.lookup || '''';
	END LOOP;
	
	-- Raise exception if replacements have failed
	IF LENGTH(v_replacement_error) > 0 THEN
		v_replacement_error := 'The following calculation attributes could not be matched for ind template with id ' || in_template_id || ':' || v_replacement_error;
		RAISE_APPLICATION_ERROR(ERR_CALC_ATTR_NOT_MATHCED, v_replacement_error);
	END IF;
	
	-- Default interval is based on task's period duration
	SELECT 1, CASE NVL(it.calc_period_duration, t.period_duration)
			WHEN 1 THEN 1
			WHEN 3 THEN 2
			WHEN 6 THEN 3
			WHEN 12 THEN 4
			ELSE 1
		 END
	  INTO v_period_set_id, v_period_interval_id
	  FROM task t, ind_template it
	 WHERE task_sid = in_task_sid
	   AND it.ind_template_id = in_template_id;
	 
	-- Extract the modified calculation xml
	SELECT EXTRACT(xml, '/').getClobVal(), stored_calc
	  INTO v_calc_xml, v_is_stored
	  FROM temp_calc;
	
	
	-- Update the indicator's calculation
	csr.calc_pkg.SetCalcXML(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_calc_ind_sid				=> in_ind_sid,
		in_calc_xml					=> v_calc_xml,
		in_is_stored				=> v_is_stored,
		in_period_set_id			=> v_period_set_id,
		in_period_interval_id		=> v_period_interval_id,
		in_do_temporal_aggregation	=> 0,
		in_calc_description			=> NULL
	);
	
	-- Add dependencies
	FOR r IN (
		SELECT DISTINCT task_sid ind_sid
		  FROM temp_task_sids
	) LOOP
		csr.calc_pkg.AddCalcDependency(security_pkg.GetAct, in_ind_sid, r.ind_sid, IND_DEP_TYPE_INDICATOR);
	END LOOP;
END;

PROCEDURE MakeNPV (
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Convert the calculation XML, this will set the default interval
	ConvertCalculation(in_task_sid, in_template_id, in_ind_sid);
	
	-- Update the indicator to reflect the correct start/end dates for the NPV calculation. 
	-- Use the indicator template's is_ongoing flag to determine if we should run the NPV 
	-- calculation to just the end of the initiative or to the end of the project's ongoing period
	UPDATE csr.ind
	   SET (calc_fixed_start_dtm, calc_fixed_end_dtm) = (
		SELECT t.start_dtm, DECODE(it.is_ongoing, 1, p.ongoing_end_dtm, t.end_dtm)
		  FROM task t, ind_template it, project p
		 WHERE t.task_sid = in_task_sid
		   AND it.ind_template_id = in_template_id
		   AND p.project_sid = t.project_sid
	   )
	 WHERE ind_sid = in_ind_sid;
END;

PROCEDURE SetMetricsForTask(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_ids			IN	security_pkg.T_SID_IDS
)
AS
	t_template_ids			security.T_SID_TABLE;
BEGIN
	
	t_template_ids := security_pkg.SidArrayToTable(in_template_ids);
	
	-- Delete anything no longer required (existing - passed)
	-- First pass, NPV
	FOR r IN (
		SELECT x.ind_template_id 
		  FROM ind_template it, (
			SELECT from_ind_template_id ind_template_id
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
			MINUS
			SELECT column_value ind_template_id
			  FROM TABLE(t_template_ids)		
		) x
		WHERE it.ind_template_id = x.ind_template_id
		  AND it.is_npv = 1
	) LOOP
		DeleteMetric(in_task_sid, r.ind_template_id);
	END LOOP;
	-- Second pass, calculations
	FOR r IN (
		SELECT x.ind_template_id 
		  FROM ind_template it, (
			SELECT from_ind_template_id ind_template_id
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
			MINUS
			SELECT column_value ind_template_id
			  FROM TABLE(t_template_ids)		
		) x
		WHERE it.ind_template_id = x.ind_template_id
		  AND it.calculation IS NOT NULL
		  AND it.is_npv = 0
	) LOOP
		DeleteMetric(in_task_sid, r.ind_template_id);
	END LOOP;
	-- Third pass, non-calculations
	FOR r IN (
		SELECT x.ind_template_id 
		  FROM ind_template it, (
			SELECT from_ind_template_id ind_template_id
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
			MINUS
			SELECT column_value ind_template_id
			  FROM TABLE(t_template_ids)		
		) x
		WHERE it.ind_template_id = x.ind_template_id
		  AND it.calculation IS NULL
		  AND it.is_npv = 0
	) LOOP
		DeleteMetric(in_task_sid, r.ind_template_id);
	END LOOP;
	
	-- Insert anything that's not already present (passed - existing)
	-- First pass, non-calculations
	FOR r IN (
		SELECT x.ind_template_id
		  FROM ind_template it, (
			SELECT column_value ind_template_id
			  FROM TABLE(t_template_ids)
			MINUS
			SELECT from_ind_template_id ind_template_id
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
		) x
		WHERE it.ind_template_id = x.ind_template_id
		  AND it.calculation IS NULL
		  AND it.is_npv = 0
	) LOOP
		CreateMetric(in_task_sid, r.ind_template_id);
	END LOOP;
	-- Second pass, calculations
	FOR r IN (
		SELECT x.ind_template_id
		  FROM ind_template it, (
			SELECT column_value ind_template_id
			  FROM TABLE(t_template_ids)
			MINUS
			SELECT from_ind_template_id ind_template_id
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
		) x
		WHERE it.ind_template_id = x.ind_template_id
		  AND it.calculation IS NOT NULL
		  AND it.is_npv = 0
	) LOOP
		CreateMetric(in_task_sid, r.ind_template_id);
	END LOOP;
	-- Third pass, NPV
	FOR r IN (
		SELECT x.ind_template_id
		  FROM ind_template it, (
			SELECT column_value ind_template_id
			  FROM TABLE(t_template_ids)
			MINUS
			SELECT from_ind_template_id ind_template_id
			  FROM task_ind_template_instance
			 WHERE task_sid = in_task_sid
		) x
		WHERE it.ind_template_id = x.ind_template_id
		  AND it.is_npv = 1
	) LOOP
		CreateMetric(in_task_sid, r.ind_template_id);
	END LOOP;
END;

PROCEDURE INTERNAL_CheckCreateRootInst(
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_start_dtm			IN	task.start_dtm%TYPE,
	out_ind_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_create				NUMBER;
BEGIN
	-- Check for existance of the root instance
	-- Avoid doing the insert after catching a NO_DATA_FOUND exception
	-- by trying to insert a placeholder, if a constraint is later added
	-- on the ind_sid then it will need to be deferred.
	BEGIN
		v_create := 1;
		INSERT INTO root_ind_template_instance
			(app_sid, from_ind_template_id, ind_sid)
		  VALUES (security_pkg.GetApp, in_template_id, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_create := 0;
			SELECT ind_sid
			  INTO out_ind_sid
			  FROM root_ind_template_instance
			 WHERE app_sid = security_pkg.GetApp
			   AND from_ind_template_id = in_template_id;
	END;

	-- Create the root instance if required
	IF v_create <> 0 THEN
		CreateIndicator(in_template_id, NULL, in_start_dtm, NULL, out_ind_sid);
		UPDATE root_ind_template_instance
		   SET ind_sid = out_ind_sid
		 WHERE app_sid = security_pkg.GetApp
		   AND from_ind_template_id = in_template_id;
		-- Create gas indicators if required
		INTERNAL_CreateGasInds(out_ind_sid);
	END IF;
END;

PROCEDURE INTERNAL_CheckCreateProjInst(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_start_dtm			IN	task.start_dtm%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	out_ind_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_project_name			project.name%TYPE;
	v_create				NUMBER;
BEGIN
	SELECT name
	  INTO v_project_name
	  FROM project
	 WHERE project_sid = in_project_sid;
	
	-- Check for existance of the project instance
	-- Avoid doing the insert after catching a NO_DATA_FOUND exception
	-- by trying to insert a placeholder, if a constraint is later added
	-- on the ind_sid then it will need to be deferred.
	BEGIN
		v_create := 1;
		INSERT INTO project_ind_template_instance
			(project_sid, from_ind_template_id, ind_sid)
		  VALUES (in_project_sid, in_template_id, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_create := 0;
			SELECT ind_sid
			  INTO out_ind_sid
			  FROM project_ind_template_instance
			 WHERE project_sid = in_project_sid
			   AND from_ind_template_id = in_template_id;
	END;

	-- Create the project instance if required
	IF v_create <> 0 THEN
		CreateIndicator(in_template_id, in_parent_ind_sid, in_start_dtm, v_project_name, out_ind_sid);
		SetIndicatorType(in_parent_ind_sid);
		UPDATE project_ind_template_instance
		   SET ind_sid = out_ind_sid
		 WHERE project_sid = in_project_sid
		   AND from_ind_template_id = in_template_id;
		-- Create gas indicators if required
		INTERNAL_CreateGasInds(out_ind_sid);
	END IF;
END;

PROCEDURE INTERNAL_CheckCreateTaskInst(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE,
	in_start_dtm			IN	task.start_dtm%TYPE,
	in_ongoing_end_dtm		IN	project.ongoing_end_dtm%TYPE,
	in_parent_ind_sid		IN	security_pkg.T_SID_ID,
	out_parent_ind_sid		OUT security_pkg.T_SID_ID
)
AS
	v_ind_sid				security_pkg.T_SID_ID;
BEGIN
	-- If no action is taken below then the parent does not change
	out_parent_ind_sid := in_parent_ind_sid;
	
	-- Check the task tree instances
	FOR r IN (
		SELECT t.lvl, t.task_sid, t.name, i.ind_sid
		  FROM task_ind_template_instance i, (
		    SELECT LEVEL lvl, task_sid, parent_task_sid, name
		     FROM task
		        START WITH task_sid = in_task_sid
		    	CONNECT BY PRIOR parent_task_sid = task_sid
		) t
		 WHERE i.task_sid(+) = t.task_sid
		   AND i.from_ind_template_id(+) = in_template_id
		   	ORDER BY t.lvl DESC
	) LOOP
		-- If the ind_sid is null then create an instance otherwise just 
		-- note the sid for use as the next parent unless we're at the 
		-- bottom of the list in which case leave the output sid alone
		IF r.ind_sid IS NOT NULL THEN
			IF r.lvl > 1 THEN
				out_parent_ind_sid := r.ind_sid;
			END IF;
		ELSE
			-- Create the metric indicator
			CreateIndicator(in_template_id, out_parent_ind_sid, in_start_dtm, r.name, r.task_sid, v_ind_sid);
			SetIndicatorType(out_parent_ind_sid);
			INSERT INTO task_ind_template_instance
				(task_sid, from_ind_template_id, ind_sid, ongoing_end_dtm)
			  VALUES(r.task_sid, in_template_id, v_ind_sid, in_ongoing_end_dtm);
			-- Call CreateGasInds after inserting into task_ind_template_instance as 
			-- gas calculation creation relies on the task_ind_template_instance table entry
			
			
			-- XXX: FB29046: HACK TO PREVENT GAS INDICATORS BEING CREATED AT THIS LEVEL FOR BARCLAYS
			--- UNTIL THE CALC ENGINE IS UPDATED AND ABLE TO HANDLE LARGER NUMBERS OF CALCULATIONS
			IF security_pkg.GetAPP <> 4914926 /*barclays.credit360.com*/ THEN
				INTERNAL_CreateGasInds(v_ind_sid);
			END IF;
			
			-- Set parent sid for next pass (unless we got to the bottom)
			IF r.lvl > 1 THEN
				out_parent_ind_sid := v_ind_sid;
			END IF;
		END IF;
	END LOOP;
END;

PROCEDURE CreateMetric(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
)
AS
	v_project_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_parent_ind_sid		security_pkg.T_SID_ID;
	v_start_dtm				task.start_dtm%TYPE;	
	v_ongoing_end_dtm		project.ongoing_end_dtm%TYPE;
BEGIN
	-- Which project does this task belong to
	-- What's the task's start dtm
	SELECT p.project_sid, p.ongoing_end_dtm, t.start_dtm
	  INTO v_project_sid, v_ongoing_end_dtm, v_start_dtm
	  FROM task t, project p
	 WHERE task_sid = in_task_sid
	   AND p.project_sid = t.project_sid;

	-- Check/create the root instance
	INTERNAL_CheckCreateRootInst(in_template_id, v_start_dtm, v_ind_sid);
	
	-- Check/create the project instance
	INTERNAL_CheckCreateProjInst(v_project_sid, in_template_id, v_start_dtm, v_ind_sid, v_ind_sid);

	-- Check the task tree instances
	INTERNAL_CheckCreateTaskInst(in_task_sid, in_template_id, v_start_dtm, v_ongoing_end_dtm, v_ind_sid, v_ind_sid);
END;

PROCEDURE INTERNAL_CleanupParentInst(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_parent_task_sid		IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
) 
AS
	v_project_sid			security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_calculation			ind_template.calculation%TYPE;
	v_is_npv				ind_template.is_npv%TYPE;
	v_count					NUMBER;
BEGIN
	-- This procedure walks up the tree cleaning up any 
	-- metric instances that are no longer required
	
	-- If the parent task sid is not null we're still dealing with the task tree
	IF in_parent_task_sid IS NOT NULL THEN
		-- Does the parent task have any children that still use the given template id
		SELECT COUNT(*)
		  INTO v_count
		  FROM task t, task_ind_template_instance ti
		 WHERE t.parent_task_sid = in_parent_task_sid
		   AND ti.task_sid = t.task_sid
		   AND ti.from_ind_template_id = in_template_id;

		IF v_count = 0 THEN
			-- Does the parent task itself use the given template id
			SELECT COUNT(*)
			  INTO v_count
			  FROM task t, task_ind_template_instance ti
			 WHERE t.task_sid = in_parent_task_sid
			   AND ti.task_sid = t.task_sid
			   AND ti.from_ind_template_id = in_template_id;
			
			IF v_count = 0 THEN
				-- The metric is no longer required
				-- delete for the parent task
				DeleteMetric(in_parent_task_sid, in_template_id);
			ELSE
				-- The parent task uses the metric but has 
				-- no more children, set the indicator type
				SELECT inst.ind_sid, it.calculation, is_npv
				  INTO v_ind_sid, v_calculation, v_is_npv
				  FROM ind_template it, task_ind_template_instance inst
				 WHERE inst.task_sid = in_parent_task_sid
				   AND inst.from_ind_template_id = in_template_id
				   AND it.ind_template_id = inst.from_ind_template_id;
				
				-- Set the indicator back to a normal indicator 
				-- (it will be sum of children as it had children)
				SetindicatorType(v_ind_sid);
				
				-- Is this a calculation?
				IF in_task_sid IS NOT NULL AND
				   v_calculation IS NOT NULL AND
				   v_is_npv = 0 THEN
				   	ConvertCalculation(in_parent_task_sid, in_template_id, v_ind_sid);
				END IF;
				
				-- NPV calculation
				IF in_task_sid IS NOT NULL AND
				   v_is_npv = 1 THEN
				   	MakeNPV(in_parent_task_sid, in_template_id, v_ind_sid);
				END IF;
			END IF;
		END IF;
	ELSE
		-- We reached the top of the task tree, get the project sid
		SELECT project_sid
		  INTO v_project_sid
		  FROM task
		 WHERE task_sid = in_task_sid;

		-- Do any parent level tasks belongong to this project still use this metric
		SELECT COUNT(*)
		  INTO v_count
		  FROM task t, task_ind_template_instance ti
		 WHERE t.project_sid = v_project_sid
		   AND ti.task_sid = t.task_sid
		   AND ti.from_ind_template_id = in_template_id;

		IF v_count = 0 THEN
			-- No more parent level tasks use this metric
			-- delete for the project
			DeleteProjectMetric(v_project_sid, in_template_id);
		END IF;
	END IF;
END;

PROCEDURE DeleteMetric(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
)
AS
	v_ind_sid				security_pkg.T_SID_ID;
	v_parent_task_sid		security_pkg.T_SID_ID;
	v_project_sid			security_pkg.T_SID_ID;
	v_count					NUMBER;
BEGIN
	-- Get the ind sid and parent task sid
	SELECT ti.ind_sid, t.parent_task_sid
	  INTO v_ind_sid, v_parent_task_sid
	  FROM task_ind_template_instance ti, task t
	 WHERE ti.task_sid = in_task_sid
	   AND ti.from_ind_template_id = in_template_id
	   AND t.task_sid = ti.task_sid;

	-- Remove any gas indicators if required
	INTERNAL_DeleteGasInds(v_ind_sid);

	-- Delete the task instance
	DELETE FROM task_ind_template_instance
	 WHERE task_sid = in_task_sid
	   AND from_ind_template_id = in_template_id;
	
	-- We're going to delete the indicator so delete all instance reeferences to that indicator
	/*
	DELETE FROM task_ind_template_instance
	 WHERE ind_sid = v_ind_sid;
	 
	DELETE FROM project_ind_template_instance
	 WHERE ind_sid = v_ind_sid;
	
	DELETE FROM root_ind_template_instance
	 WHERE ind_sid = v_ind_sid; 

	security_pkg.DebugMsg('v_ind_sid: '||v_ind_sid);
	*/
	
	-- Delete the csr indicator (via security)	
	securableobject_pkg.DeleteSO(security_pkg.GetAct, v_ind_sid);
	
	-- Clean-up no longer required instances that were above the deleted instance
	INTERNAL_CleanupParentInst(in_task_sid, v_parent_task_sid, in_template_id);
END;

PROCEDURE DeleteProjectMetric(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
)
AS
	v_ind_sid				security_pkg.T_SID_ID;
	v_count					NUMBER;
BEGIN
	SELECT pi.ind_sid
	  INTO v_ind_sid
	  FROM project_ind_template_instance pi
	 WHERE pi.project_sid = in_project_sid
	   AND pi.from_ind_template_id = in_template_id;

	-- Delete the project instance
	DELETE FROM project_ind_template_instance
	 WHERE project_sid = in_project_sid
	   AND from_ind_template_id = in_template_id;

	-- Delete the csr indicator (via security)
	securableobject_pkg.DeleteSO(security_pkg.GetAct, v_ind_sid);

	-- Do any projects in this applicaton still use this metric
	SELECT COUNT(*)
	  INTO v_count
	  FROM project p, project_ind_template_instance pi
	 WHERE p.app_sid = security_pkg.GetApp
	   AND pi.project_sid = p.project_sid
	   AND pi.from_ind_template_id = in_template_id;

	IF v_count = 0 THEN
		-- No more projects use this metric
		-- delete the root metric
		DeleteRootMetric(in_template_id);
	END IF;
END;

PROCEDURE DeleteRootMetric(
	in_template_id			IN	ind_template.ind_template_id%TYPE
)
AS
	v_ind_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT ri.ind_sid
	  INTO v_ind_sid
	  FROM root_ind_template_instance ri
	 WHERE ri.app_sid = security_pkg.GetApp
	   AND ri.from_ind_template_id = in_template_id;

	-- Delete the root instance
	DELETE FROM root_ind_template_instance
	 WHERE app_sid = security_pkg.GetApp
	   AND from_ind_template_id = in_template_id;

	-- Delete the csr indicator (via security)
	securableobject_pkg.DeleteSO(security_pkg.GetAct, v_ind_sid);
END;

PROCEDURE MoveMetric(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_old_parent_sid		IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
)
AS
	v_inst_ind_sid			security_pkg.T_SID_ID;
	v_parent_ind_sid		security_pkg.T_SID_ID;
	v_project_sid			security_pkg.T_SID_ID;
	v_start_dtm				task.start_dtm%TYPE;
	v_ongoing_end_dtm		task_ind_template_instance.ongoing_end_dtm%TYPE;
BEGIN
	-- Get the new parent task sid, the project sid and the task's start date
	SELECT ti.ind_sid, t.project_sid, t.start_dtm, ti.ongoing_end_dtm
	  INTO v_inst_ind_sid, v_project_sid, v_start_dtm, v_ongoing_end_dtm
	  FROM task_ind_template_instance ti, task t
	 WHERE ti.task_sid = in_task_sid
	   AND ti.from_ind_template_id = in_template_id
	   AND t.task_sid = ti.task_sid;
	
	-- Check the root/project/parent instances exist before we move the indicator instance
	INTERNAL_CheckCreateRootInst(in_template_id, v_start_dtm, v_parent_ind_sid);
	INTERNAL_CheckCreateProjInst(v_project_sid, in_template_id, v_start_dtm, v_parent_ind_sid, v_parent_ind_sid);
	INTERNAL_CheckCreateTaskInst(in_task_sid, in_template_id, v_start_dtm, v_ongoing_end_dtm, v_parent_ind_sid, v_parent_ind_sid);
	
	-- Move the indicator instance to the new parent instances
	csr.indicator_pkg.MoveIndicator(security_pkg.GetACT, v_inst_ind_sid, v_parent_ind_sid);
	SetIndicatorType(v_parent_ind_sid);
	
	-- Clean-up no longer required instances that were above the moved instance
	INTERNAL_CleanupParentInst(in_task_sid, in_old_parent_sid, in_template_id);
END;

PROCEDURE MoveMetrics(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_old_parent_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT from_ind_template_id ind_template_id
		  FROM task_ind_template_instance
		 WHERE task_sid = in_task_sid
	) LOOP
		MoveMetric(in_task_sid, in_old_parent_sid, r.ind_template_id);
	END LOOP;
END;

PROCEDURE SetIndicatorType(
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
	v_period_set_id			csr.ind.period_set_id%TYPE;
	v_period_interval_id	csr.ind.period_interval_id%TYPE;
	v_divisibility			csr.ind.divisibility%TYPE;
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.ind i
	 WHERE parent_sid = in_ind_sid
	   AND i.map_to_ind_sid IS NULL;

	SELECT i.period_set_id, i.period_interval_id, NVL(i.divisibility, m.divisibility)
	  INTO v_period_set_id, v_period_interval_id, v_divisibility
	  FROM csr.ind i
	  LEFT JOIN csr.measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
	 WHERE i.ind_sid = in_ind_sid;

	IF v_count > 0 THEN
		-- If indicator has children set to calc
		IF v_divisibility != csr.csr_data_pkg.DIVISIBILITY_AVERAGE THEN
			-- Sum of children
			csr.calc_pkg.SetCalcXML(
				in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_calc_ind_sid				=> in_ind_sid,
				in_calc_xml					=> '<sum sid=''' || in_ind_sid || '''/>',
				in_is_stored				=> 0,
				in_period_set_id			=> v_period_set_id,
				in_period_interval_id		=> v_period_interval_id,
				in_do_temporal_aggregation	=> 0,
				in_calc_description			=> NULL
			);
		ELSE
			-- Average of children
			csr.calc_pkg.SetCalcXML(
				in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_calc_ind_sid				=> in_ind_sid,
				in_calc_xml					=> '<average sid=''' || in_ind_sid || '''/>',
				in_is_stored				=> 0,
				in_period_set_id			=> v_period_set_id,
				in_period_interval_id		=> v_period_interval_id,
				in_do_temporal_aggregation	=> 0,
				in_calc_description			=> NULL
			);
		END IF;
		csr.calc_pkg.AddCalcDependency(security_pkg.GetAct, in_ind_sid, in_ind_sid, IND_DEP_TYPE_CHILDREN);
	ELSE
		-- Otherwise clear calc
		csr.calc_pkg.SetCalcXML(
			in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_calc_ind_sid				=> in_ind_sid,
			in_calc_xml					=> '<nop/>',
			in_is_stored				=> 0,
			in_period_set_id			=> v_period_set_id,
			in_period_interval_id		=> v_period_interval_id,
			in_do_temporal_aggregation	=> 0,
			in_calc_description			=> NULL
		);
	END IF;
END;

PROCEDURE InheritMetrics(
	in_task_sid				IN	security_pkg.T_SID_ID
)
AS
	v_parent_task_sid		security_pkg.T_SID_ID;
BEGIN
	-- This operation is only valid for child tasks
	SELECT parent_task_sid
	  INTO v_parent_task_sid
	  FROM task
	 WHERE task_sid = in_task_sid;

	IF v_parent_task_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NO_PARENT_TASK, 'Tasks must have a parent task to inherit metrics');
	END IF;

	-- Create the same set of metrics for the new child
	-- This manages the 'sum of children' indicator calculation for us
	FOR r IN (
		SELECT inst.from_ind_template_id template_id
		  FROM task_ind_template_instance inst, ind_template it
		 WHERE inst.task_sid = v_parent_task_sid
		   AND it.ind_template_id = inst.from_ind_template_id
		   	ORDER BY it.calculation NULLS FIRST, it.is_npv ASC
	) LOOP
		CreateMetric(in_task_sid, r.template_id);
	END LOOP;
END;

/*
PROCEDURE CreateTemplate (
	in_name					IN	ind_template.name%TYPE,
	in_description			IN	ind_template.description%TYPE,
	in_input_label			IN	ind_template.input_label%TYPE,
	in_tolerance_type		IN	ind_template.tolerance_type%TYPE,
	in_pct_upper_tolerance	IN	ind_template.pct_upper_tolerance%TYPE,
	in_pct_lower_tolerance	IN	ind_template.pct_lower_tolerance%TYPE,
	in_measure_sid			IN	ind_template.measure_sid%TYPE,
	in_scale				IN	ind_template.scale%TYPE,
	in_format_mask			IN	ind_template.format_mask%TYPE,
	in_traget_direction		IN	ind_template.target_direction%TYPE,
	in_info_xml				IN	ind_template.info_xml%TYPE,
	in_divisibility			IN	ind_template.divisible%TYPE,
	in_aggregate			IN	ind_template.aggregate%TYPE,
	in_ongoing_period		IN	ind_template.ongoing_period%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TOOD:...
	NULL;
END;

PROCEDURE
)
AS
BEGIN
	-- TOOD:...
	NULL;
END;
*/

/*
PROCEDURE DeleteTemplate (
	in_ind_template_id		IN	ind_template.ind_template_id%TYPE,
)
AS
BEGIN
END;
*/

PROCEDURE RemoveTemplateFromProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_name		IN	ind_template.name%TYPE
)
AS
	v_template_id			ind_template.ind_template_id%TYPE;
BEGIN
	BEGIN
		-- Try to find the id associated with the specified name
		-- and which is associated with the given project
		SELECT it.ind_template_id
		  INTO v_template_id
		  FROM ind_template it, project_ind_template pit
		 WHERE pit.app_sid = security_pkg.GetAPP
		   AND pit.project_sid = in_project_sid
		   AND it.ind_template_id = pit.ind_template_id
		   AND LOWER(it.name) = LOWER(in_template_name);
		   -- Found an associated template id
		   RemoveTemplateFromProject(in_project_sid, v_template_id);
	EXCEPTION
		-- Noting to remove
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
END;

PROCEDURE RemoveTemplateFromProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_template_id			IN	ind_template.ind_template_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_project_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to project with SID ' || in_project_sid);
	END IF;

	-- Delete metrics
	FOR r IN (
		SELECT t.task_sid
		  FROM ind_template it, project_ind_template pit, project p, task t
		 WHERE it.ind_template_id = in_template_id
		   AND pit.ind_template_id = it.ind_template_id
		   AND p.app_sid = security_pkg.GetAPP
		   AND p.project_sid = in_project_sid
		   AND p.project_sid = pit.project_sid
		   AND t.project_sid = p.project_sid
	) LOOP
		DeleteMetric(r.task_sid, in_template_id);
	END LOOP;

	-- Remove the template from the project
	DELETE FROM project_ind_template
	 WHERE app_sid = security_pkg.GetAPP
	   AND project_sid = in_project_sid
	   AND ind_template_id = in_template_id;
END;

PROCEDURE TriggerNPVRecalc(
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT inst.ind_sid, it.ind_template_id, it.is_ongoing
		  FROM task_ind_template_instance inst, ind_template it
		 WHERE inst.task_sid = in_task_sid
		   AND it.ind_template_id = inst.from_ind_template_id
		   AND it.is_npv = 1
	) LOOP
		-- Make sure the start/end dates are correct
		UPDATE csr.ind
		   SET (calc_fixed_start_dtm, calc_fixed_end_dtm) = (
			SELECT t.start_dtm, DECODE(r.is_ongoing, 1, p.ongoing_end_dtm, t.end_dtm)
			  FROM task t, project p
			 WHERE t.task_sid = in_task_sid
			   AND p.project_sid = t.project_sid
		   )
		 WHERE ind_sid = r.ind_sid;
		 
		-- ALL NPV metric instances are stored calculation indicators
		csr.calc_pkg.AddJobsForCalc(r.ind_sid);
	END LOOP;
END;

PROCEDURE RenameIndTemplate (
	in_name				IN	ind_template.name%TYPE,
	in_description		IN	ind_template.description%TYPE,
	in_input_label		IN	ind_template.input_label%TYPE
)
AS
	v_ind_template_id	ind_template.ind_template_id%TYPE;
BEGIN
	SELECT ind_template_id
	  INTO v_ind_template_id
	 FROM ind_template
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  AND name = in_name;
	  
	RenameIndTemplate(v_ind_template_id, in_description, in_input_label);
END;

PROCEDURE RenameIndTemplate (
	in_ind_template_id	IN	ind_template.ind_template_id%TYPE,
	in_description		IN	ind_template.description%TYPE,
	in_input_label		IN	ind_template.input_label%TYPE
)
AS
BEGIN
	UPDATE ind_template
	   SET description = NVL(in_description, description),
	   	   input_label = NVL(in_input_label, NVL(in_description, description))
	 WHERE ind_template_id = in_ind_template_id;
	
	IF in_description IS NOT NULL THEN
		FOR r IN (
			SELECT ind_sid
			  FROM root_ind_template_instance
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND from_ind_template_id = in_ind_template_id
		) LOOP
			csr.indicator_pkg.RenameIndicator(r.ind_sid, in_description);
		END LOOP;
	END IF;
END;

PROCEDURE SetInfoText (
	in_name				IN	ind_template.name%TYPE,
	in_info				IN	ind_template.description%TYPE
) 
AS
	v_ind_template_id	ind_template.ind_template_id%TYPE;
BEGIN
	SELECT ind_template_id
	  INTO v_ind_template_id
	 FROM ind_template
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  AND name = in_name;
	  
	SetInfoText(v_ind_template_id, in_info);
END;

PROCEDURE SetInfoText (
	in_ind_template_id	IN	ind_template.ind_template_id%TYPE,
	in_info				IN	ind_template.description%TYPE
) 
AS
BEGIN
	UPDATE ind_template
	   SET info_text = in_info
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_template_id = in_ind_template_id;
END;

END ind_template_pkg;
/
