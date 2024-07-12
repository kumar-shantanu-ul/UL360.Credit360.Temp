SPOOL metricUpdate.log

DECLARE
	v_ongoing_dtm			DATE;
	v_region_count			NUMBER;
	v_default_ongoing_dtm	DATE := DATE '2013-01-01';
BEGIN
	-- Find all "ongoing" metrics
	FOR r IN (
		SELECT it.app_sid, ind_template_id, NVL(ongoing_period, 12) ongoing_period
		  FROM actions.ind_template it
		 WHERE ind_template_id IN (
			SELECT ind_template_id
			  FROM actions.ind_template 
			 WHERE LOWER(name) LIKE '%_ongoing'
			UNION
			SELECT ongoing_template_id ind_template_id
			  FROM actions.project_ind_template
			 WHERE ongoing_template_id IS NOT NULL
		)
		ORDER BY it.app_sid, ind_template_id
	) LOOP	 
		-- Try and compute an ongoing end dtm for project using the end dtm of the initiative 
		-- (we know that up until now the ongoing end date was 12 months ahead of the initiative end date so we can use that value)
		FOR p IN (
			SELECT project_sid
			  FROM actions.project_ind_template
			 WHERE app_sid = r.app_sid
			   AND ind_template_id = r.ind_template_id
			 	ORDER BY project_sid
		) LOOP
			-- Try to get an end date from any initiatives in this project
			SELECT ADD_MONTHS(MAX(end_dtm), 12)
		  	  INTO v_ongoing_dtm
		  	  FROM actions.task
		  	 WHERE project_sid = p.project_sid;
		  	-- Update the project 
			dbms_output.put_line('Setting ongoing end date for project_sid '||p.project_sid||' = '||v_ongoing_dtm);
			UPDATE actions.project
			   SET ongoing_end_dtm = v_ongoing_dtm
			 WHERE project_sid = p.project_sid;
		END LOOP;
		
		-- Second pass, fix up projects that still don't have an end date
		FOR p IN (
			SELECT p.app_sid, p.project_sid
			  FROM actions.project_ind_template pit, actions.project p
			 WHERE pit.app_sid = r.app_sid
			   AND p.app_sid = r.app_sid
			   AND pit.ind_template_id = r.ind_template_id
			   AND p.project_sid = pit.project_sid
			   AND p.ongoing_end_dtm IS NULL
			   	ORDER BY pit.project_sid
		) LOOP
			SELECT MAX(end_dtm)
		  	  INTO v_ongoing_dtm
		  	  FROM actions.project
		  	 WHERE app_sid = p.app_sid;
		  	IF v_ongoing_dtm IS NOT NULL THEN
				dbms_output.put_line('Project''s ongoing end dtm was null, using other projects in this app to set the date for '||p.project_sid||' = '||v_ongoing_dtm);
			ELSE
				-- Still no date, default it to 01-JAN-2013
				dbms_output.put_line('Could not find an ongoing end date for this project, defaulting '||p.project_sid||' = '||v_ongoing_dtm);
				v_ongoing_dtm := v_default_ongoing_dtm;
			END IF;
			-- Update the project
			UPDATE actions.project
			   SET ongoing_end_dtm = v_ongoing_dtm
			 WHERE project_sid = p.project_sid;
		END LOOP;
		
		-- Update period duration column and set ongoing flag
		UPDATE actions.ind_template
		   SET per_period_duration = r.ongoing_period,
		   	   is_ongoing = 1
		 WHERE ind_template_id = r.ind_template_id;	 
	
		-- Update the template instance table's ongoing end dates (based on actual task data)
		FOR i IN (
			SELECT t.task_sid, ADD_MONTHS(end_dtm, 12) ongoing_dtm
			  FROM actions.task t, actions.task_ind_template_instance inst
			 WHERE t.app_sid = r.app_sid
			   AND inst.app_sid = r.app_sid
			   AND t.task_sid = inst.task_sid
			   AND inst.from_ind_template_id = r.ind_template_id
			   	ORDER BY inst.from_ind_template_id, inst.task_sid
		) LOOP
			dbms_output.put_line('Setting ongoing end date for task_sid '||i.task_sid||', ind_template_id '||r.ind_template_id||' = '||i.ongoing_dtm);
			UPDATE actions.task_ind_template_instance
			   SET ongoing_end_dtm = i.ongoing_dtm
			 WHERE task_sid = i.task_sid
			   AND from_ind_template_id = r.ind_template_id;
		END LOOP;		
	END LOOP;
	
	-- Initiatives projects all have icons set at present
	-- Check for any projects that still don't have an ongoing end date set (they will not 
	-- have any  project ind template rererences) and default them to 01-JAN-2013
	FOR p IN (
		SELECT project_sid
		  FROM actions.project
		 WHERE icon IS NOT NULL
		   AND ongoing_end_dtm IS NULL
		   	ORDER BY project_sid
	) LOOP
		dbms_output.put_line('Project with sid '||p.project_sid||' still has no ongoong end date set '||v_ongoing_dtm);
		UPDATE actions.project
		   SET ongoing_end_dtm = v_default_ongoing_dtm
		 WHERE project_sid = p.project_sid;
	END LOOP;
	
	-- Set the initiatives flag on all projects with an icon
	UPDATE actions.project 
	   SET is_initiatives = 1 
	 WHERE icon IS NOT NULL;
	
	-- Update with data from non-ongoing period
	UPDATE actions.ind_template
	   SET per_period_duration = period
	 WHERE period IS NOT NULL;
	
	-- Update the values in the template instance table
	FOR task_loop IN (
		SELECT app_sid, task_sid, project_sid
		  FROM actions.task
		  	ORDER BY app_sid, project_sid, task_sid
	) LOOP
		-- Count regions
		SELECT COUNT(*)
		  INTO v_region_count
		  FROM actions.task_region
		 WHERE app_sid = task_loop.app_sid
		   AND task_sid = task_loop.task_sid;
		 
		-- Update value for each static metric for this initiative (task)
		FOR v IN (
			SELECT ind_template_id, entry_measure_conversion_id,
				--
				CASE WHEN period IS NOT NULL THEN val_period
					 WHEN ongoing_period IS NOT NULL THEN val_ongoing
					 WHEN divisible = 0 THEN val_indivisible
					 ELSE val_sum
				END * v_region_count val,
				--
				CASE WHEN period IS NOT NULL THEN entry_val_period
					 WHEN ongoing_period IS NOT NULL THEN entry_val_ongoing
					 WHEN divisible = 0 THEN entry_val_indivisible
					 ELSE entry_val_sum
				END * v_region_count entry_val
				--
			  FROM (
				SELECT t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, t.region_sid, t.pos_group, t.pos,
					t.measure_sid, v.entry_measure_conversion_id, t.default_value, t.period, t.ongoing_period, t.divisible, t.input_dp, is_mandatory,
					--
					ROUND(MAX(v.val_number) * MAX(t.period) / MAX(t.period_duration), 8) val_period,
					ROUND(MAX(v.val_number) * MAX(t.ongoing_period) / MAX(t.period_duration), 8) val_ongoing,
					MAX(v.val_number) val_indivisible,
					ROUND(SUM(v.val_number),8) val_sum,
					--
					ROUND(MAX(NVL(v.entry_val_number, v.val_number)) * MAX(t.period) / MAX(t.period_duration), 8) entry_val_period,
					ROUND(MAX(NVL(v.entry_val_number, v.val_number)) * MAX(t.ongoing_period) / MAX(t.period_duration), 8) entry_val_ongoing,
					MAX(NVL(v.entry_val_number, v.val_number)) entry_val_indivisible,
					ROUND(SUM(NVL(v.entry_val_number, v.val_number)),8) entry_val_sum
					--
				  FROM (
			        SELECT it.ind_template_id, it.name, it.description, it.input_label, it.divisible, it.period, it.ongoing_period,
			        		inst.ind_sid, pit.pos_group, pit.pos, pit.default_value, pit.input_dp, pit.is_mandatory,
			        		i.measure_sid, rgn.region_sid, t.period_duration,
			        		DECODE(ongoing_period, NULL, t.start_dtm, t.end_dtm) start_dtm,
			        		DECODE(ongoing_period, NULL, t.end_dtm, ADD_MONTHS(t.end_dtm, 12)) end_dtm
			          FROM actions.task t, actions.ind_template it, actions.project_ind_template pit, actions.task_ind_template_instance inst, csr.ind i, (
			          		-- We are only going to select the first row because we know that the static
			          		-- metric data should be the same for all regions associated with the initiative
			          		SELECT region_sid
			          		  FROM actions.task_region
			          		 WHERE app_sid = task_loop.app_sid
			          		   AND task_sid = task_loop.task_sid
			          		   AND ROWNUM = 1
			          ) rgn
			         WHERE t.app_sid = task_loop.app_sid
			           AND it.app_sid = task_loop.app_sid
			           AND pit.app_sid = task_loop.app_sid
			           AND inst.app_sid = task_loop.app_sid
			           AND i.app_sid = task_loop.app_sid
			           AND it.ind_template_id = pit.ind_template_id
			           AND it.calculation IS NULL
			           AND pit.project_sid = task_loop.project_sid
			           AND pit.update_per_period = 0
			           AND inst.task_sid = task_loop.task_sid
					   AND inst.from_ind_template_id = it.ind_template_id
					   AND t.task_sid = inst.task_sid
					   AND i.ind_sid(+) = inst.ind_sid
				    ) t, csr.val v
				 WHERE v.app_sid = task_loop.app_sid
				   AND v.ind_sid(+) = t.ind_sid
				   AND v.region_sid(+) = t.region_sid
				   AND v.period_start_dtm(+) >= t.start_dtm
		           AND v.period_end_dtm(+) <= t.end_dtm
				   	GROUP BY t.ind_template_id, t.name, t.description, t.input_label, t.ind_sid, t.region_sid, t.pos_group, t.pos,
				   		t.measure_sid, v.entry_measure_conversion_id, t.default_value, t.input_dp, t.is_mandatory, t.period, t.ongoing_period, t.divisible, t.period_duration
			) x
			ORDER BY ind_template_id
		) LOOP
			dbms_output.put_line('Setting value for task_sid '||task_loop.task_sid||', ind_template_id '||v.ind_template_id||' = '||v.val||' ('||v.entry_val||')');
			UPDATE actions.task_ind_template_instance
			   SET val = v.val,
			   	   entry_val = v.entry_val,
			   	   entry_measure_conversion_id = v.entry_measure_conversion_id
			 WHERE app_sid = task_loop.app_sid
			   AND task_sid = task_loop.task_sid
			   AND from_ind_template_id = v.ind_template_id;
		END LOOP;
	END LOOP;
	
	-- Update calculation template xml
	FOR i IN (
		SELECT app_sid, ind_template_id, calculation
		  FROM actions.ind_template it
		 WHERE it.calculation IS NOT NULL
	) LOOP
		-- Get the xml into a table so it can be manipulated
		DELETE FROM actions.temp_calc;
		INSERT INTO actions.temp_calc (xml, stored_calc) (
			SELECT calculation, is_stored_calc
			  FROM actions.ind_template
			 WHERE app_sid = i.app_sid
			   AND ind_template_id = i.ind_template_id
		);	
		-- Loop over the referenced template names
		FOR r IN (
			SELECT EXTRACT(VALUE(x), '//path/@sid').getStringVal() name
	          FROM TABLE(XMLSEQUENCE(EXTRACT(i.calculation, '//path'))) x
		) LOOP
			-- Delete any existing template attributes
			UPDATE actions.temp_calc
			   SET xml = DELETEXML(xml, '//path[@sid="'||r.name||'"]/@template')
			 WHERE EXISTSNODE(xml, '//path[@sid="'||r.name||'"]/@template') = 1;
			-- Insert the new template attribute (currently in the sid attribute)
			UPDATE actions.temp_calc
			   SET xml = INSERTCHILDXML(xml, '//path[@sid="'||r.name||'"]', '@template', r.name);
			-- Delete any existing sid attributes
			UPDATE actions.temp_calc
			   SET xml = DELETEXML(xml, '//path[@template="'||r.name||'"]/@sid')
			 WHERE EXISTSNODE(xml, '//path[@template="'||r.name||'"]/@sid') = 1;
		END LOOP;
		-- Update the template xml (there will only be one row in temp_calc)
		UPDATE actions.ind_template
		   SET calculation = (SELECT xml FROM actions.temp_calc)
		 WHERE app_sid = i.app_sid
		   AND ind_template_id = i.ind_template_id;
	END LOOP;
	
END;
/

SPOOL OFF
