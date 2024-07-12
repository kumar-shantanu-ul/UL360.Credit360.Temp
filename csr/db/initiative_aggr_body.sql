CREATE OR REPLACE PACKAGE BODY CSR.initiative_aggr_pkg
IS

PROCEDURE AuditLogTrace(
	in_id	IN	NUMBER,
	in_msg	IN	VARCHAR2)
AS
BEGIN
	NULL;
	--csr_data_pkg.WriteAuditLogEntry(security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_INITIATIVE, security_pkg.GetAPP,
	--	in_id, in_msg,
	--	CURRENT_TIMESTAMP
	--);
END;

-- The main functionality for fetching the periodic values for initiative metrics
PROCEDURE INTERNAL_PrepAggrData
AS
	v_cur						SYS_REFCURSOR;
	v_tbl						T_NORMALISED_VAL_TABLE;
	v_tbl_duration_1			T_NORMALISED_VAL_TABLE;
	v_period_count				NUMBER;
	v_n_period					NUMBER;
	v_val						NUMBER(24,10);
	v_start_dtm					DATE;
	v_end_dtm					DATE;

	v_normalized_start_dtm		DATE;
	v_normalized_end_dtm		DATE;
	v_partial_val				NUMBER(24,10);
	v_initiative_temp_saving_apportion		BOOLEAN;
BEGIN
	
	-- We have to process each initiaitve seperately in case we need to ramp the values.
	-- We can sum over each initiative after we've processed the normalised values for each initiative.
	FOR r IN (
		-- Selects the periodic values for each initiative regardless of "flow state derived indicator association"
		SELECT i.initiative_sid, i.project_start_dtm, i.project_end_dtm, i.running_start_dtm, i.running_end_dtm, i.is_ramped,
			   val.initiative_metric_id, val.val, im.per_period_duration, im.one_off_period, im.is_during, im.is_running, im.is_rampable,
			   DECODE(im.per_period_duration, NULL, im.divisibility, csr_data_pkg.DIVISIBILITY_LAST_PERIOD) divisibility, -- force last period so normalisation doesn't divide the vlaues up
			   NVL(im.per_period_duration, i.period_duration) period_duration,
			   NVL(rag.aggr_region_sid, ir.region_sid) region_sid
		  FROM initiative_metric im
		  JOIN initiative_metric_val val ON im.initiative_metric_id = val.initiative_metric_id AND im.app_sid = val.app_sid
		  JOIN initiative i ON val.initiative_sid = i.initiative_sid AND val.app_sid = i.app_sid
		  JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND i.app_sid = ir.app_sid
		  LEFT JOIN aggr_region rag ON ir.region_sid = rag.region_sid AND ir.app_sid = rag.app_sid
		  JOIN temp_initiative_sids tis ON tis.initiative_sid = i.initiative_sid
		  JOIN temp_initiative_metric_ids tim ON tim.initiative_metric_id = im.initiative_metric_id
	)
	LOOP

		-- Special case for one-off values
		IF r.one_off_period IS NOT NULL THEN
			
			-- If the is_during and is_running flags are both set then the start 
			-- of the project period takes precedence, if the project start date 
			-- is not set then we use the running start date.
			
			-- Project period part
			IF r.is_during != 0 AND
			   r.project_start_dtm IS NOT NULL AND
			   r.project_end_dtm IS NOT NULL THEN

				INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
				  VALUES (
					r.initiative_sid,
					r.initiative_metric_id,
					r.region_sid,
					ADD_MONTHS(r.project_start_dtm, r.one_off_period * r.period_duration),
					ADD_MONTHS(r.project_start_dtm, (r.one_off_period + 1) * r.period_duration),
					r.val
				);

			-- Running period part
			ELSIF r.is_running != 0 AND
			   r.running_start_dtm IS NOT NULL AND
			   r.running_end_dtm IS NOT NULL THEN

				INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
				  VALUES (
					r.initiative_sid,
					r.initiative_metric_id,
					r.region_sid,
					ADD_MONTHS(r.running_start_dtm, r.one_off_period * r.period_duration),
					ADD_MONTHS(r.running_start_dtm, (r.one_off_period + 1) * r.period_duration),
					r.val
				);
			END IF;

		-- Normally spread values
		ELSE
			
			-- XXX: I want to be able to set both the is_during and is_running flag on 
			-- a metric so it appears on the edit page for both temporary and ongoing 
			-- initiatives. If both flags are set them we don't want to double count 
			-- the metric values in areas where the project and running periods may 
			-- overlap. If both flags are set them ramping doesn't make sense.
			IF r.is_during != 0 THEN
				
				-- Select the correct date range
				IF r.is_running = 0 THEN
					v_start_dtm := r.project_start_dtm;
					v_end_dtm := r.project_end_dtm;
				ELSE
					v_start_dtm := LEAST(NVL(r.project_start_dtm, r.running_start_dtm), NVL(r.running_start_dtm, r.project_start_dtm));
					v_end_dtm := GREATEST(NVL(r.project_end_dtm, r.running_end_dtm), NVL(r.running_end_dtm, r.project_end_dtm));
				END IF;
				
				-- Project period part if only project flag is set 
				-- or overall part of both during and running flags are set
				IF v_start_dtm IS NOT NULL AND
				   v_end_dtm IS NOT NULL AND
				   v_end_dtm > v_start_dtm THEN

					-- Normalise periods
					v_normalized_start_dtm := v_start_dtm;
					v_normalized_end_dtm := v_end_dtm;

					-- TSQ-999
					v_initiative_temp_saving_apportion := csr_data_pkg.CheckCapability('Initiative Temp Saving Apportion');
					IF v_initiative_temp_saving_apportion THEN
						v_normalized_start_dtm := TRUNC(v_start_dtm, 'YEAR');
						v_normalized_end_dtm := TRUNC(v_end_dtm, 'YEAR');
						IF v_end_dtm != v_normalized_end_dtm
						THEN
							v_normalized_end_dtm := ADD_MONTHS(v_normalized_end_dtm, 12);
						END IF;

						AuditLogTrace(r.initiative_sid, 'Normalise val='||r.val||' to '||v_normalized_start_dtm||' - '||v_normalized_end_dtm||' for duration='||r.period_duration||' and divis='||r.divisibility);
					END IF;

					OPEN v_cur FOR
					SELECT r.region_sid region_sid, v_normalized_start_dtm start_dtm, v_normalized_end_dtm end_dtm, r.val
					  FROM dual;
					v_tbl := val_pkg.NormaliseToPeriodSpan(v_cur, v_normalized_start_dtm, v_normalized_end_dtm, r.period_duration, r.divisibility);
					CLOSE v_cur;

					IF v_initiative_temp_saving_apportion THEN
						-- Sum monthly values that occur in the partial duration before the first whole duration
						FOR i IN v_tbl.FIRST .. v_tbl.LAST
						LOOP
							IF v_tbl(i).val_number IS NOT NULL AND
								v_tbl(i).start_dtm < v_start_dtm AND
								v_tbl(i).end_dtm > v_start_dtm
							THEN
								IF v_tbl(i).start_dtm < v_start_dtm THEN
									AuditLogTrace(r.initiative_sid, 'Before val '||v_tbl(i).val_number||' for '||v_tbl(i).start_dtm||' to '||v_tbl(i).end_dtm);
								END IF;

								OPEN v_cur FOR
								SELECT r.region_sid region_sid, v_tbl(i).start_dtm start_dtm, v_tbl(i).end_dtm end_dtm, r.val
								FROM dual;
								v_tbl_duration_1 := val_pkg.NormaliseToPeriodSpan(v_cur, v_tbl(i).start_dtm, v_tbl(i).end_dtm, 1, csr_data_pkg.DIVISIBILITY_DIVISIBLE);
								CLOSE v_cur;

								v_partial_val := 0;
								FOR j IN v_tbl_duration_1.FIRST .. v_tbl_duration_1.LAST
								LOOP
									AuditLogTrace(r.initiative_sid,
										'Before Partial val '||v_tbl_duration_1(j).val_number||' for '||v_tbl_duration_1(j).start_dtm||' to '||v_tbl_duration_1(j).end_dtm||
										' for actual start '||v_start_dtm
									);
									IF v_tbl_duration_1(j).val_number IS NOT NULL AND
										v_tbl_duration_1(j).start_dtm >= v_start_dtm AND
										v_tbl_duration_1(j).end_dtm <= v_tbl(i).end_dtm
									THEN
										AuditLogTrace(r.initiative_sid,
											'Before Partial val added '||v_tbl_duration_1(j).val_number||' for '||v_tbl_duration_1(j).start_dtm||' to '||v_tbl_duration_1(j).end_dtm||
											' for actual start '||v_start_dtm
										);
										v_partial_val := v_partial_val + v_tbl_duration_1(j).val_number;
									END IF;
								END LOOP;

								IF v_partial_val IS NOT NULL AND v_partial_val != 0 THEN
									INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
									VALUES (
										r.initiative_sid,
										r.initiative_metric_id,
										v_tbl(i).region_sid, 
										v_tbl(i).start_dtm, 
										v_tbl(i).end_dtm, 
										v_partial_val
									);
									AuditLogTrace(r.initiative_sid, 'Before Partial val = '||v_partial_val||' for '||v_tbl(i).start_dtm||' to '||v_tbl(i).end_dtm);
								END IF;
							END IF;
						END LOOP;
					END IF;

					-- Values that occur in whole durations
					FOR i IN v_tbl.FIRST .. v_tbl.LAST
					LOOP
						IF v_tbl(i).start_dtm >= v_start_dtm AND
						   v_tbl(i).end_dtm <= v_end_dtm
						THEN
							INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
							VALUES (
								r.initiative_sid,
								r.initiative_metric_id,
								v_tbl(i).region_sid, 
								v_tbl(i).start_dtm, 
								v_tbl(i).end_dtm, 
								v_tbl(i).val_number
							);
						ELSE
							AuditLogTrace(r.initiative_sid, 'Ignored val '||v_tbl(i).val_number||' for '||v_tbl(i).start_dtm||' to '||v_tbl(i).end_dtm);
						END IF;
					END LOOP;

					IF v_initiative_temp_saving_apportion THEN
						-- Sum monthly values that occur in the partial duration after the last whole duration
						FOR i IN v_tbl.FIRST .. v_tbl.LAST
						LOOP
							IF v_tbl(i).val_number IS NOT NULL AND
								v_tbl(i).start_dtm < v_end_dtm AND
								v_tbl(i).end_dtm > v_end_dtm
							THEN
								IF v_tbl(i).end_dtm > v_end_dtm THEN
									AuditLogTrace(r.initiative_sid, 'After - val '||v_tbl(i).val_number||' for '||v_tbl(i).start_dtm||' to '||v_tbl(i).end_dtm);
								END IF;

								OPEN v_cur FOR
								SELECT r.region_sid region_sid, v_tbl(i).start_dtm start_dtm, v_tbl(i).end_dtm end_dtm, r.val
								FROM dual;
								v_tbl_duration_1 := val_pkg.NormaliseToPeriodSpan(v_cur, v_tbl(i).start_dtm, v_tbl(i).end_dtm, 1, csr_data_pkg.DIVISIBILITY_DIVISIBLE);
								CLOSE v_cur;

								v_partial_val := 0;
								FOR j IN v_tbl_duration_1.FIRST .. v_tbl_duration_1.LAST
								LOOP
									AuditLogTrace(r.initiative_sid,
										'After Partial val '||v_tbl_duration_1(j).val_number||' for '||v_tbl_duration_1(j).start_dtm||' to '||v_tbl_duration_1(j).end_dtm||
										' for actual start '||v_start_dtm
									);
									IF v_tbl_duration_1(j).val_number IS NOT NULL AND
										v_tbl_duration_1(j).start_dtm <= v_end_dtm AND
										v_tbl_duration_1(j).end_dtm <= v_end_dtm --v_tbl(i).end_dtm
									THEN
										AuditLogTrace(r.initiative_sid,
											'After Partial val added '||v_tbl_duration_1(j).val_number||' for '||v_tbl_duration_1(j).start_dtm||' to '||v_tbl_duration_1(j).end_dtm||
											' for actual start '||v_start_dtm
										);
										v_partial_val := v_partial_val + v_tbl_duration_1(j).val_number;
									END IF;
								END LOOP;

								IF v_partial_val IS NOT NULL AND v_partial_val != 0 THEN
									INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
									VALUES (
										r.initiative_sid,
										r.initiative_metric_id,
										v_tbl(i).region_sid, 
										v_tbl(i).start_dtm, 
										v_tbl(i).end_dtm, 
										v_partial_val
									);
									AuditLogTrace(r.initiative_sid, 'After Partial val = '||v_partial_val||' for '||v_tbl(i).start_dtm||' to '||v_tbl(i).end_dtm);
								END IF;
							END IF;
						END LOOP;
					END IF;

				END IF;

			-- ELSE if the during flag is not set then process the running period part 
			ELSIF r.is_running != 0 AND
			      r.running_start_dtm IS NOT NULL AND
			      r.running_end_dtm IS NOT NULL AND
			   	  r.running_end_dtm > r.running_start_dtm THEN

			 	-- Normalise periods
			   	OPEN v_cur FOR
				SELECT r.region_sid region_sid, r.running_start_dtm start_dtm, r.running_end_dtm end_dtm, r.val
				  FROM dual;
				v_tbl := val_pkg.NormaliseToPeriodSpan(v_cur, r.running_start_dtm, r.running_end_dtm, r.period_duration, r.divisibility);
				CLOSE v_cur;

				-- If ramping is switched on for the initiative AND
				-- ramping is switched on for the metric AND
				-- the project period is not null AND
				-- the project and running periods overlap
				IF r.is_ramped = 1 AND r.is_rampable = 1 AND
			   	  r.project_start_dtm IS NOT NULL AND
			   	  r.project_end_dtm IS NOT NULL AND
			   	  r.project_end_dtm > r.running_start_dtm AND
			   	  r.project_start_dtm < r.running_end_dtm
			   	THEN
			   		-- Copy values over into a new structure containing the ind_sid, ramping during the overlapping period.
			   		-- Where:
			   		-- r is rmaped value
			   		-- x is normalised value
			   		-- n is ramp period (one-based)
			   		-- N is total number of rmap periods
			   		-- then:
			   		-- r(n) = n * x(n) / (N + 1)

			   		-- Compute v_period_count (N)
			   		v_period_count := MONTHS_BETWEEN(TRUNC(r.project_end_dtm, 'MONTH'), TRUNC(r.running_start_dtm, 'MONTH')) / r.period_duration;

					FOR i IN v_tbl.FIRST .. v_tbl.LAST
					LOOP
						-- Get the value as we might modify it dueing ramping
						v_val := v_tbl(i).val_number;

						-- Do ramping in overlap range only
						IF v_tbl(i).start_dtm >= r.running_start_dtm AND
						   v_tbl(i).start_dtm < r.project_end_dtm THEN
						   	-- COMPUTE v_n_period (n)
							v_n_period := (MONTHS_BETWEEN(TRUNC(v_tbl(i).start_dtm, 'MONTH'), TRUNC(r.running_start_dtm, 'MONTH')) / r.period_duration) + 1;
							-- Compute ramped value
							v_val := (v_n_period * v_val) / (v_period_count + 1);
						END IF;

						-- Poke the value back into the new structure
						INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
				  		  VALUES (
							r.initiative_sid,
							r.initiative_metric_id,
							v_tbl(i).region_sid,
							v_tbl(i).start_dtm,
							v_tbl(i).end_dtm,
							v_val
						);
					END LOOP;
				-- XXX: DISABLED (SEE BELOW)
				-- If ramping is switched on for the initiative AND
				-- *but* ramping is switched *off* for the metric AND
				-- the project period is not null AND
				-- the project and running periods overlap
				-- 
				-- Note: If the metric would have been ramped but it's ramping flag is switched 
				-- off then we start copying at the project end date, not the running start date.
				/*
				ELSIF r.is_ramped = 1 AND r.is_rampable = 0 AND
					  r.project_start_dtm IS NOT NULL AND
				   	  r.project_end_dtm IS NOT NULL AND
				   	  r.project_end_dtm > r.running_start_dtm AND
				   	  r.project_start_dtm < r.running_end_dtm
				THEN
					FOR i IN v_tbl.FIRST .. v_tbl.LAST
					LOOP
						IF v_tbl(i).start_dtm >= r.project_end_dtm THEN
							INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
					  		  VALUES (
								r.initiative_sid,
								r.initiative_metric_id,
								v_tbl(i).region_sid,
								v_tbl(i).start_dtm,
								v_tbl(i).end_dtm,
								v_tbl(i).val_number
							);
					  	END IF;
					END LOOP;
				*/
				-- XXX: With the above disabled, the non-ramped metrics for ramped initiatives will be output
				-- at the running start date. This is actually a more consistent and straightforward approach.
				--No ramping, just copy values over into a new structure without any ramping.
				ELSE
					
					FOR i IN v_tbl.FIRST .. v_tbl.LAST
					LOOP
						INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
				  		  VALUES (
							r.initiative_sid,
							r.initiative_metric_id,
							v_tbl(i).region_sid,
							v_tbl(i).start_dtm,
							v_tbl(i).end_dtm,
							v_tbl(i).val_number
						);
				  	END LOOP;
				END IF;
			END IF;
		END IF;
	END LOOP;
END;

PROCEDURE INTERNAL_PrepNetPeriods
AS
BEGIN
	-- The code that pulls the net values requires there to be a row for the 
	-- period in which the net value will fall, if there's no row in a given 
	-- period then no net value will be output. The rows produced during data 
	-- preparation are only created for periods during the time period of the 
	-- initiative, this means that any net values that fall net_period months 
	-- after the initiative need rows creating so the net value query returns 
	-- the correct results.
	FOR r IN (
		-- Select possible net periods for given metrics
		SELECT DISTINCT t.initiative_metric_id, imi.net_period
		  FROM temp_initiative_aggr_val t
		  JOIN initiative_metric_state_ind imi ON t.initiative_metric_id = imi.initiative_metric_id
		 WHERE imi.net_period IS NOT NULL
	) LOOP
		-- Insert null value rows but only if no row already exists for that initiative, metric, region, period
		INSERT INTO temp_initiative_aggr_val (initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number) (
			SELECT initiative_sid, initiative_metric_id, region_sid, ADD_MONTHS(start_dtm, r.net_period), ADD_MONTHS(end_dtm, r.net_period), NULL
			  FROM temp_initiative_aggr_val
			 WHERE initiative_metric_id = r.initiative_metric_id
			MINUS
			SELECT initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, NULL
			  FROM temp_initiative_aggr_val
			 WHERE initiative_metric_id = r.initiative_metric_id
		);
	END LOOP;
END;

-- Called by scrag to get aggregated periodic indicator values for associated metrics
PROCEDURE GetIndicatorValues(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_t_init_aggr_val_table		T_INITIATIVE_AGGR_VAL_DATA_TABLE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run aggregates');
	END IF;

	-- Prep a fetch potentially covering all initiatives and all metrics
	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT initiative_sid 
		  FROM initiative
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	INSERT INTO temp_initiative_metric_ids (initiative_metric_id)
		SELECT initiative_metric_id 
		  FROM initiative_metric
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- Prep the aggregate data
	INTERNAL_PrepAggrData;
	
	-- Prep rows for net value outputs, at present this preperartion is only required when 
	-- generating the aggregate indicator outputs as the UI does not show the net values
	INTERNAL_PrepNetPeriods;
	
	SELECT T_INITIATIVE_AGGR_VAL_DATA_ROW(initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
	  BULK COLLECT INTO v_t_init_aggr_val_table
	  FROM temp_initiative_aggr_val;
	
	OPEN out_cur FOR
		SELECT ind_sid, region_sid, period_start_dtm, period_end_dtm, source_type_id, error_code, val_number
		  FROM (
			-- Count contributing initiatives based on flow state 
			SELECT /*+CARDINALITY(t, 200000) CARDINALITY(n, 200000)*/
				   fsg.count_ind_sid ind_sid, t.region_sid, t.start_dtm period_start_dtm, t.end_dtm period_end_dtm, 
				   csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, null error_code,
			       COUNT(DISTINCT t.initiative_Sid) val_number -- Return the initiative count as the value (crunch up multiple metric matches)
			  FROM TABLE(v_t_init_aggr_val_table) t
			  JOIN initiative init ON init.initiative_sid = t.initiative_sid
			  JOIN flow_item fit ON init.flow_item_id = fit.flow_item_id
			  JOIN flow_state_group_member fgm ON fit.current_state_id = fgm.flow_state_id
			  JOIN flow_State_group fsg ON fsg.flow_state_group_id = fgm.flow_state_group_id
			 WHERE fsg.count_ind_sid IS NOT NULL
			 GROUP BY fsg.count_ind_sid, t.region_sid, t.start_dtm, t.end_dtm 
			UNION
			-- Count contributing initiatives based on tag
		 	SELECT /*+CARDINALITY(t, 200000)*/
				   atg.count_ind_sid ind_sid, t.region_sid, t.start_dtm period_start_dtm, t.end_dtm period_end_dtm, 
				   csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, null error_code,
			       COUNT(DISTINCT t.initiative_Sid) val_number -- Return the initiative count as the value (crunch up multiple metric matches)
			  FROM TABLE(v_t_init_aggr_val_table) t
			  JOIN initiative_tag itag ON t.initiative_sid = itag.initiative_sid
			  JOIN aggr_tag_group_member atgm ON itag.tag_id = atgm.tag_id
			  JOIN aggr_tag_group atg ON atg.aggr_tag_group_id = atgm.aggr_tag_group_id
			 WHERE atg.count_ind_sid IS NOT NULL
			 GROUP BY atg.count_ind_sid, t.region_sid, t.start_dtm, t.end_dtm 
			UNION
			-- Aggregated initiative values
			SELECT ind_sid, region_sid, start_dtm period_start_dtm, end_dtm period_end_dtm,
			   csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, null error_code,
			   DECODE(aggregate, 'AVERAGE', avg_val_number, sum_val_number) val_number
			  FROM (
				SELECT ind_sid, region_sid, start_dtm, end_dtm, aggregate,
					SUM(val_number) sum_val_number, AVG(val_number) avg_val_number
				FROM (
					-- Where state matched metric/ind and no equivelent tag match metric/ind
					SELECT /*+CARDINALITY(t, 200000) CARDINALITY(n, 200000)*/
						   t.initiative_sid, i.ind_sid, t.region_sid, t.start_dtm, t.end_dtm, i.aggregate,
					       imi.flow_state_group_id, NULL aggr_tag_group_id,
					       -- If the net period for indicator is null then n.val_number 
					       -- will always be null and this will just return t.val_number
					       DECODE(n.val_number, null, t.val_number, NVL(t.val_number, 0)) - NVL(n.val_number, 0) val_number
					  FROM TABLE(v_t_init_aggr_val_table) t
					  JOIN initiative init ON init.initiative_sid = t.initiative_sid
					  JOIN flow_item fit ON init.flow_item_id = fit.flow_item_id
					  JOIN flow_state_group_member fgm ON fit.current_state_id = fgm.flow_state_id
					  JOIN initiative_metric_state_ind imi ON t.initiative_metric_id = imi.initiative_metric_id AND fgm.flow_state_group_id = imi.flow_state_group_id
					  JOIN ind i ON imi.ind_sid = i.ind_sid
					  JOIN initiatives_options opt ON opt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					  -- Get values net_period months ago for computing net values
					  LEFT JOIN TABLE(v_t_init_aggr_val_table) n
					  		 ON imi.net_period IS NOT NULL
					  		AND t.initiative_sid = n.initiative_sid
					  		AND t.initiative_metric_id = n.initiative_metric_id
					  		AND t.region_sid = n.region_sid
					  		AND t.start_dtm = ADD_MONTHS(n.start_dtm, imi.net_period)
					 -- Filter out stuff that's also associated with a tag
					 WHERE (imi.initiative_metric_id, imi.ind_sid, imi.measure_sid) NOT IN (
						SELECT imti.initiative_metric_id, imti.ind_sid, imti.measure_sid
						  FROM initiative_metric_tag_ind imti
	           			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					  )
					   -- Filter out values before/after current report date
					   AND (
						   opt.current_report_date IS NULL 
						OR fgm.after_report_date = 1 AND t.start_dtm >= opt.current_report_date
						OR fgm.before_report_date = 1 AND t.end_dtm <= opt.current_report_date
				      )
					UNION
					-- Where tag matches metric/ind and no equivelent state match metric/ind
					SELECT /*+CARDINALITY(t, 200000)*/
						   t.initiative_sid, i.ind_sid, t.region_sid, t.start_dtm, t.end_dtm, i.aggregate,
					       NULL flow_state_group_id, imti.aggr_tag_group_id, t.val_number
					  FROM TABLE(v_t_init_aggr_val_table) t
					  JOIN initiative_tag itag ON t.initiative_sid = itag.initiative_sid
					  JOIN aggr_tag_group_member atgm ON itag.tag_id = atgm.tag_id
					  JOIN initiative_metric_tag_ind imti ON t.initiative_metric_id = imti.initiative_metric_id AND atgm.aggr_tag_group_id = imti.aggr_tag_group_id
					  JOIN ind i ON imti.ind_sid = i.ind_sid
				     WHERE (imti.initiative_metric_id, imti.ind_sid, imti.measure_sid) NOT IN (
						SELECT imi.initiative_metric_id, imi.ind_sid, imi.measure_sid
						  FROM initiative_metric_state_ind imi
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				      )
					UNION
					-- Where both state and tag match metric/ind
					SELECT /*+CARDINALITY(t, 200000) CARDINALITY(n, 200000)*/
						   t.initiative_sid, i.ind_sid, t.region_sid, t.start_dtm, t.end_dtm, i.aggregate,
					       imi.flow_state_group_id, imti.aggr_tag_group_id,
					       -- If the net period for the indicator is null then n.val_number 
					       -- will always be null and this will just retutn t.val_number
					       DECODE(n.val_number, null, t.val_number, NVL(t.val_number, 0)) - NVL(n.val_number, 0) val_number
					  FROM TABLE(v_t_init_aggr_val_table) t
					  JOIN initiative init ON init.initiative_sid = t.initiative_sid
					  JOIN flow_item fit ON init.flow_item_id = fit.flow_item_id
					  JOIN flow_state_group_member fgm ON fit.current_state_id = fgm.flow_state_id
					  JOIN initiative_metric_state_ind imi ON t.initiative_metric_id = imi.initiative_metric_id AND fgm.flow_state_group_id = imi.flow_state_group_id
					  JOIN initiative_tag itag ON t.initiative_sid = itag.initiative_sid
					  JOIN aggr_tag_group_member atgm ON itag.tag_id = atgm.tag_id
					  JOIN initiative_metric_tag_ind imti ON t.initiative_metric_id = imti.initiative_metric_id AND atgm.aggr_tag_group_id = imti.aggr_tag_group_id
					  JOIN ind i ON imi.ind_sid = i.ind_sid
					  JOIN initiatives_options opt ON opt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					  -- Get values net_period months ago for computing net values
					  LEFT JOIN TABLE(v_t_init_aggr_val_table) n
					  		 ON imi.net_period IS NOT NULL
					  		AND t.initiative_sid = n.initiative_sid
					  		AND t.initiative_metric_id = n.initiative_metric_id
					  		AND t.region_sid = n.region_sid
					  		AND t.start_dtm = ADD_MONTHS(n.start_dtm, imi.net_period)
				     WHERE imti.initiative_metric_id = imi.initiative_metric_id
				       AND imti.ind_sid = imi.ind_sid
				       AND imti.measure_sid = imi.measure_sid
				       -- Filter out values before/after current report date
					   AND (
						   opt.current_report_date IS NULL 
						OR fgm.after_report_date = 1 AND t.start_dtm >= opt.current_report_date
						OR fgm.before_report_date = 1 AND t.end_dtm <= opt.current_report_date
				      )
					)
					GROUP BY ind_sid, region_sid, start_dtm, end_dtm, aggregate
				)
			)
		 ORDER BY ind_sid, region_sid, period_start_dtm;
END;

-- Called by UI to fetch periodic metric data for a set of metrics/initiatives
-- Assumes the temp tables initiative_sids and initiative_metric_ids are filled in prior to the call
PROCEDURE GetPeriodicMetricVals(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_t_init_aggr_val_table		T_INITIATIVE_AGGR_VAL_DATA_TABLE;
	v_t_init_metric_id_table	T_INITIATIVE_METRIC_ID_DATA_TABLE;
BEGIN
	
	INTERNAL_PrepAggrData;
	
	SELECT T_INITIATIVE_METRIC_ID_DATA_ROW(initiative_metric_id, measure_conversion_id)
	  BULK COLLECT INTO v_t_init_metric_id_table
	  FROM temp_initiative_metric_ids;
	
	SELECT T_INITIATIVE_AGGR_VAL_DATA_ROW(initiative_sid, initiative_metric_id, region_sid, start_dtm, end_dtm, val_number)
	  BULK COLLECT INTO v_t_init_aggr_val_table
	  FROM temp_initiative_aggr_val;
	
	OPEN out_cur FOR
		SELECT t.initiative_sid, t.initiative_metric_id, t.region_sid, t.start_dtm, t.end_dtm, im.lookup_key, im.measure_sid, m.measure_conversion_id,
			measure_pkg.UNSEC_GetConvertedValue(t.val_number, m.measure_conversion_id, t.start_dtm) val_number
		  FROM TABLE(v_t_init_aggr_val_table) t
		  JOIN TABLE(v_t_init_metric_id_table) m ON m.initiative_metric_id = t.initiative_metric_id
		  JOIN initiative_metric im ON im.initiative_metric_id = t.initiative_metric_id AND im.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	;
END;

-- Called by UI to fetch periodic metric data for a set of metrics/initiatives
-- Fills the temp tables initiative_sids and initiative_metric_ids based on the passed arrays
PROCEDURE GetPeriodicMetricVals(
	in_initiative_sids			IN	security_pkg.T_SID_IDS,
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_initiative_sids			security.T_SID_TABLE;
	t_metric_ids				security.T_SID_TABLE;
BEGIN
	t_initiative_sids := security_pkg.SidArrayToTable(in_initiative_sids);
	t_metric_ids := security_pkg.SidArrayToTable(in_metric_ids);
	
	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT column_value
		  FROM TABLE(t_initiative_sids);
	
	INSERT INTO temp_initiative_metric_ids (initiative_metric_id)
		SELECT column_value
		  FROM TABLE(t_metric_ids);
		  
	GetPeriodicMetricVals(out_cur);
END;

-- Called by UI to fetch periodic metric data for a set of metrics/initiatives
-- Fills the temp tables initiative_sids and initiative_metric_ids based on the passed arrays, supports conversions
PROCEDURE GetPeriodicMetricVals(
	in_initiative_sids			IN	security_pkg.T_SID_IDS,
	in_metric_ids				IN	security_pkg.T_SID_IDS,
	in_conversion_ids			IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_initiative_sids			security.T_SID_TABLE;
	t_metric_ids				security.T_ORDERED_SID_TABLE;
	t_conversion_ids			security.T_ORDERED_SID_TABLE;
BEGIN
	t_initiative_sids := security_pkg.SidArrayToTable(in_initiative_sids);
	t_metric_ids := security_pkg.SidArrayToOrderedTable(in_metric_ids);
	t_conversion_ids := security_pkg.SidArrayToOrderedTable(in_conversion_ids);
	
	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT column_value
		  FROM TABLE(t_initiative_sids);
	
	INSERT INTO temp_initiative_metric_ids (initiative_metric_id, measure_conversion_id)
		SELECT m.sid_id, c.sid_id
		  FROM TABLE(t_metric_ids) m, TABLE(t_conversion_ids) c
		 WHERE m.pos = c.pos;
		  
	GetPeriodicMetricVals(out_cur);
END;

PROCEDURE GetPeriodicMetricValsByKey(
	in_initiative_sids			IN	security_pkg.T_SID_IDS,
	in_metric_keys				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_initiative_sids			security.T_SID_TABLE;
	t_metric_keys				security.T_VARCHAR2_TABLE;
BEGIN
	t_initiative_sids := security_pkg.SidArrayToTable(in_initiative_sids);
	t_metric_keys := security_pkg.Varchar2ArrayToTable(in_metric_keys);
	
	INSERT INTO temp_initiative_sids (initiative_sid)
		SELECT column_value
		  FROM TABLE(t_initiative_sids);
	
	INSERT INTO temp_initiative_metric_ids (initiative_metric_id)
		SELECT m.initiative_metric_id
		  FROM initiative_metric m, TABLE(t_metric_keys) k
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.lookup_key = k.value;
		  
	GetPeriodicMetricVals(out_cur);
END;

--

PROCEDURE RefreshAggrVals(
	in_initiative_sid			IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
BEGIN
	-- XXX: We're not using the initiative sid at
	-- the moment but may be useful in future
	-- XXX: aggregate group key is hard coded at the moment.
	FOR r IN (
		SELECT name
		  FROM aggregate_ind_group
		 WHERE name = 'INITIATIVE_INDS'
	) LOOP
		aggregate_ind_pkg.RefreshGroup(r.name);
	END LOOP;
END;

PROCEDURE RefreshAggrRegions(
	in_initiative_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT region_sid
		  FROM initiative_region
		 WHERE initiative_sid = in_initiative_sid
	) LOOP
		UpdateAggrRegions(r.region_sid);
		--UpdateAggrRegionsFast(r.region_sid);
	END LOOP;
END;

PROCEDURE CreateAggrRegion (
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_region_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_desc					region_description.description%TYPE;
	v_dup_desc				region_description.description%TYPE;
	v_duplicate_count		NUMBER(10);
	v_try_again				BOOLEAN;
BEGIN
	-- Check for existing aggr region
	FOR r IN (
		SELECT aggr_region_sid
		  FROM aggr_region
		 WHERE region_sid = in_region_sid
	) LOOP
		out_region_sid := r.aggr_region_sid;
		RETURN;
	END LOOP;

	-- Get parent name and description
	SELECT description
	  INTO v_desc
	  FROM v$region
	 WHERE region_sid = in_region_sid;

	-- Create the new aggr region as a child
	v_dup_desc := v_desc;
	v_duplicate_count := 0;
	v_try_again := TRUE;
	WHILE v_try_again 
	LOOP
		BEGIN
			region_pkg.CreateRegion(
				in_parent_sid		=> in_region_sid,
				in_name				=> v_dup_desc,
				in_description		=> v_dup_desc,
				in_region_type		=> csr_data_pkg.REGION_TYPE_AGGR_REGION,
				out_region_sid		=> out_region_sid
			);
			v_try_again := FALSE;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_dup_desc := v_desc || ' (aggr)';
				v_duplicate_count := v_duplicate_count + 1;
				IF v_duplicate_count > 1 THEN
					v_dup_desc := v_desc||' (aggr '||v_duplicate_count||')';
				END IF;
				v_try_again := TRUE;
		END;
	END LOOP;
	
	-- Update the agr region table
	INSERT INTO aggr_region
		(region_sid, aggr_region_sid)
	  VALUES (in_region_sid, out_region_sid);
END;

PROCEDURE DeleteAggrRegion (
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT aggr_region_sid
		  FROM aggr_region
		 WHERE region_sid = in_region_sid
	) LOOP
		-- Remove from aggr_region
		DELETE FROM aggr_region
		 WHERE region_sid = in_region_sid
		   AND aggr_region_sid = r.aggr_region_sid;
		-- Delete the region node
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, r.aggr_region_sid);
	END LOOP;
END;

---

PROCEDURE INTERNAL_UpdateAggrRegion (
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_found_here			BOOLEAN := FALSE;
	v_found_beneath			BOOLEAN := FALSE;
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	-- Check this node
	FOR r IN (
		SELECT initiative_sid
		  FROM initiative_region
		 WHERE region_sid = in_region_sid
	) LOOP
		v_found_here := TRUE;
		EXIT;
	END LOOP;

	-- Check all nodes beneath
	FOR r IN (
		SELECT ir.region_sid
		  FROM initiative_region ir, (
			SELECT region_sid
			  FROM region r
				START WITH parent_sid = in_region_sid
				CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		  ) r
		 WHERE r.region_sid = ir.region_sid
	) LOOP
		v_found_beneath := TRUE;
		EXIT;
	END LOOP;

	IF v_found_here AND v_found_beneath THEN
		CreateAggrRegion(in_region_sid, v_region_sid);
	ELSE
		DeleteAggrRegion(in_region_sid);
	END IF;
END;

PROCEDURE UpdateAggrRegions (
	in_region_sid			security_pkg.T_SID_ID
)
AS
BEGIN
	-- Check/update each region node going up the tree, starting at this node
	FOR r IN (
		SELECT region_sid
		  FROM (
			SELECT LEVEL lvl, r.region_sid, r.region_type
			  FROM region r
			 WHERE r.link_to_region_sid is NULL
			   AND region_type != csr_data_pkg.REGION_TYPE_ROOT
				START WITH region_sid = in_region_sid
				CONNECT BY PRIOR parent_sid = NVL(link_to_region_sid, region_sid)
		) ORDER BY lvl
	) LOOP
		INTERNAL_UpdateAggrRegion(r.region_sid);
	END LOOP;
END;

---

FUNCTION INTERNAL_CheckForInitiative(
	in_region_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		SELECT initiative_sid
		  FROM initiative_region
		 WHERE region_sid = in_region_sid
	) LOOP
		RETURN TRUE;
	END LOOP;
	RETURN FALSE;
END;

PROCEDURE UpdateAggrRegionsFast (
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_found					BOOLEAN := FALSE;
	v_found_here			BOOLEAN;
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	-- Check/update each region node going up the tree
	FOR r IN (
		SELECT region_sid
		  FROM (
			SELECT LEVEL lvl, r.region_sid, r.region_type
			  FROM region r
			 WHERE r.link_to_region_sid is NULL
			   AND region_type != csr_data_pkg.REGION_TYPE_ROOT
				START WITH region_sid = in_region_sid
				CONNECT BY PRIOR parent_sid = NVL(link_to_region_sid, region_sid)
		) ORDER BY lvl
	) LOOP
		v_found_here := INTERNAL_CheckForInitiative(r.region_sid);
		IF v_found AND v_found_here THEN
			CreateAggrRegion(r.region_sid, v_region_sid);
		ELSE
			NULL;
			-- XXX: Cant delete because we've not checked all child
			-- nodes (or indeed any child nodes at the start point)
			-- DeleteAggrRegion(r.region_sid);
		END IF;
		v_found := v_found OR v_found_here;
	END LOOP;
END;

---

PROCEDURE CreateGroupInds(
	in_parent_ind_sid		security_pkg.T_SID_ID,
	in_state_group_id		flow_state_group.flow_State_group_id%TYPE,
	in_tag_group_id			aggr_tag_group.aggr_tag_group_id%TYPE DEFAULT NULL
)
AS
	v_parent_ind_sid		security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_name					ind.name%TYPE;
	v_desc					ind_description.description%TYPE;
	v_aggr					ind.aggregate%TYPE;
	v_count					NUMBER;
BEGIN
	
	-- XXX: For now this procedure only works if there's 
	-- a state group, the tag group is optional
	
	SELECT lookup_key, label
	  INTO v_name, v_desc
	  FROM flow_state_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND flow_state_group_id = in_state_group_id;
	  
	
	v_parent_ind_sid := in_parent_ind_sid;
	-- Create/get the parent group folder
	/*
	BEGIN
		indicator_pkg.CreateIndicator(
			in_parent_sid_id	=> in_parent_ind_sid,
			in_name 			=> v_name,
			in_description 		=> v_desc,
			out_sid_id			=> v_parent_ind_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT ind_sid
			  INTO v_parent_ind_sid
			  FROM ind
			 WHERE parent_sid = in_parent_ind_sid
			   AND name = v_name;
	END;
	*/
	
	-- Fill TEMP_INITIATIVE_METRIC_IDS if required
	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_initiative_metric_ids;
	
	IF v_count = 0 THEN
		INSERT INTO temp_initiative_metric_ids (initiative_metric_id)
			SELECT initiative_metric_id
			  FROM initiative_metric
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	-- For each metric create an indicator and map it to the metric for this group
	-- XXX: Exclude measured metrics for the moment!
	FOR r IN (
		SELECT m.initiative_metric_id, m.measure_sid, m.label, m.divisibility
		  FROM initiative_metric m, temp_initiative_metric_ids t, (
			SELECT m.initiative_metric_id
			  FROM initiative_metric m
			 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND m.initiative_metric_id IN (
				SELECT DISTINCT pimfs.initiative_metric_id
				  FROM project_init_metric_flow_state pimfs, project_initiative_metric pim, flow_state_group_member fgm
				 WHERE pimfs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND pim.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND pimfs.project_sid = pim.project_sid
				   AND pimfs.initiative_metric_id = pim.initiative_metric_id
				   AND pim.update_per_period = 0
				   AND pimfs.flow_state_id = fgm.flow_state_id
				   AND fgm.flow_state_group_id = in_state_group_id
		  	)
			/*MINUS
			SELECT DISTINCT initiative_metric_id
			  FROM initiative_metric_state_ind
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND flow_state_group_id = in_state_group_id
			*/
		) x
		  WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.initiative_metric_id = x.initiative_metric_id
		   AND m.initiative_metric_id = t.initiative_metric_id
	) LOOP
		
		IF r.divisibility = csr_data_pkg.DIVISIBILITY_AVERAGE THEN
			v_aggr := 'AVERAGE';
		ELSE
			v_aggr := 'SUM';	
		END IF;
	
		indicator_pkg.CreateIndicator(
			in_parent_sid_id		=> v_parent_ind_sid,
			in_name 				=> SUBSTR(REPLACE(r.label,'/','\'), 0, 255),
			in_description 			=> r.label,
			in_measure_sid			=> r.measure_sid,
			in_aggregate			=> v_aggr,
			in_divisibility			=> r.divisibility,
			in_ind_type				=> csr_data_pkg.IND_TYPE_AGGREGATE,
			in_is_system_managed	=> 1,
			out_sid_id				=> v_ind_sid
		);
		
		INSERT INTO initiative_metric_state_ind (initiative_metric_id, flow_state_group_id, ind_sid, measure_sid)
			VALUES(r.initiative_metric_id, in_state_group_id, v_ind_sid, r.measure_sid);
		
		-- XXX: This assumes that initiative_metric_tag_ind and initiative_metric_state_ind are in sync.
		IF in_tag_group_id IS NOT NULL THEN
			INSERT INTO initiative_metric_tag_ind (initiative_metric_id, aggr_tag_group_id, ind_sid, measure_sid)
				VALUES (r.initiative_metric_id, in_tag_group_id, v_ind_sid, r.measure_sid);
		END IF;
		
	END LOOP;
	
END;

-- private
PROCEDURE AssertWriteAccess
AS
	v_initiatives_sid		security_pkg.T_SID_ID;
BEGIN
	v_initiatives_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Initiatives');
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_initiatives_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write to the initiatives container: ' || v_initiatives_sid);
	END IF;
END;

-- private
FUNCTION GetCurrentReportDate
RETURN initiatives_options.current_report_date%TYPE
AS
	v_current_date			initiatives_options.current_report_date%TYPE;
BEGIN
	SELECT current_report_date
	  INTO v_current_date
	  FROM initiatives_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	RETURN v_current_date;
END;

PROCEDURE ClearReportDate
AS
	v_current_date			initiatives_options.current_report_date%TYPE;
BEGIN
	AssertWriteAccess;

	v_current_date := GetCurrentReportDate;

	-- Only update/recalc if there's a date to clear
	IF v_current_date IS NOT NULL THEN
		
		-- Update the report date
		UPDATE initiatives_options
		   SET current_report_date = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		 
		-- Recompute aggregate ind data
		RefreshAggrVals;
	END IF;
END;

PROCEDURE SetReportDate(
	in_report_date		IN	initiatives_options.current_report_date%TYPE
)
AS
	v_current_date			initiatives_options.current_report_date%TYPE;
BEGIN
	AssertWriteAccess;

	v_current_date := GetCurrentReportDate;

	-- Only update/recalc if the date has changed
	IF v_current_date IS NULL OR
	   v_current_date != in_report_date THEN
	
		-- Update the report date
		UPDATE initiatives_options
		   SET current_report_date = in_report_date
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		 
		-- Recompute aggregate ind data
		RefreshAggrVals;
	END IF;
END;

PROCEDURE UNSEC_CopyIndRelationship(
	in_from_ind_sid		security_pkg.T_SID_ID,
	in_to_ind_sid		security_pkg.T_SID_ID,
	in_net_period		initiative_metric_state_ind.net_period%TYPE
)
AS
BEGIN
	-- Quick clone of anything relating to the old indicator.
	-- We only expect one instance of any given indicator in the initiative_metric_state_ind table.
	
	INSERT INTO initiative_metric_state_ind
		(initiative_metric_id, flow_state_group_id, ind_sid, measure_sid, net_period)
			SELECT msi.initiative_metric_id, msi.flow_state_group_id, in_to_ind_sid, i.measure_sid, in_net_period
			  FROM initiative_metric_state_ind msi
			  JOIN ind i ON i.ind_sid = in_to_ind_sid
			 WHERE msi.ind_sid = in_from_ind_sid;
			 
	INSERT INTO initiative_metric_tag_ind
		(initiative_metric_id, aggr_tag_group_id, ind_sid, measure_sid)
			SELECT mti.initiative_metric_id, mti.aggr_tag_group_id, in_to_ind_sid, i.measure_sid
			  FROM initiative_metric_tag_ind mti
			  JOIN ind i ON i.ind_sid = in_to_ind_sid
			 WHERE mti.ind_sid = in_from_ind_sid;
END;

PROCEDURE UNSEC_UpdateAggrGroup
AS
BEGIN
	FOR agg IN (
		SELECT aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE name = 'INITIATIVE_INDS'
	) LOOP
		FOR i IN (
			SELECT mi.ind_sid, m.label 
			  FROM initiative_metric_state_ind mi, initiative_metric m
			 WHERE m.initiative_metric_id = mi.initiative_metric_id
			UNION
			SELECT ti.ind_sid, m.label
			  FROM initiative_metric_tag_ind ti, initiative_metric m
			 WHERE m.initiative_metric_id = ti.initiative_metric_id
		)
		LOOP
			BEGIN
				INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
					VALUES (agg.aggregate_ind_group_id, i.ind_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;
		
		aggregate_ind_pkg.RefreshGroup(agg.aggregate_ind_group_id);
		
	END LOOP;
END;

END initiative_aggr_pkg;
/
