  DECLARE
	v_app_sid NUMBER(10);
	CURSOR c IS
		SELECT v.VAL_ID, V.IND_SID, I.DESCRIPTION IND_DESCRIPTION, 
			V.REGION_SID, R.DESCRIPTION REGION_DESCRIPTION, 
			v.PERIOD_START_DTM, v.PERIOD_END_DTM, v.VAL_NUMBER, vc.changed_by_sid, v.source_id  
		  FROM VAL v, IND i, REGION r, VAL_CHANGE vc
		 WHERE v.ind_sid = i.ind_sid
		   AND v.region_sid =r.region_sid
		   AND i.app_sid = v_app_sid
		   AND v.last_val_change_id = vc.val_change_id 
		 ORDER BY v.REGION_SID, v.IND_SID, v.PERIOD_START_DTM, v.PERIOD_END_DTM DESC;
	r_last  c%ROWTYPE;
	r_overlap c%ROWTYPE;
	v_overlap	BOOLEAN;
	v_overlap_sum	NUMBER(18,4);
	v_output	VARCHAR2(4000);
	v_to_delete	VARCHAR2(4000);
	v_problem_count	NUMBER(10);
	v_solved_count	NUMBER(10);
	v_keep 		VARCHAR2(4);
	v_set_val_id	NUMBER(10);
	CURSOR c_delete(to_delete VARCHAR2) IS
		SELECT v.region_sid, v.ind_sid, v.period_start_dtm, v.period_end_dtm, v.val_id
		  FROM TABLE(utils_pkg.splitString(to_delete,',')) s, VAL v
		 WHERE s.item = v.Val_id;
	v_fixed  NUMBER(10);
	in_act_id VARCHAR(38);
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,in_act_id);
	v_app_sid := securableobject_pkg.GetSIDFromPath(in_act_id,0,'//aspen/applications/rk.credit360.com');
	v_overlap := FALSE;
	v_output := '';
	v_to_delete := '';
	v_problem_count := 0;
	v_solved_count := 0;
	FOR r IN c LOOP
		--
		IF NOT v_overlap THEN
			-- we're not in an overlap situation... or are we? check...
			IF r_last.ind_sid = r.ind_sid AND r_last.region_sid = r.region_sid AND r.period_start_dtm < r_last.period_end_dtm THEN
				v_overlap := TRUE;
				r_overlap := r_last;
				v_overlap_sum := 0;
				v_to_delete := '';				
				v_output := r_overlap.val_id||' overlaps '; --||'|'||r.ind_sid||'|'||r.ind_description||'|'||r.region_sid||'|'||r.region_description||'|'||r_overlap.period_start_dtm||'|'||r_overlap.period_end_dtm||'|'||r_overlap.val_number||CHR(10);				
			END IF;
		END IF;			
		--
		IF v_overlap THEN
			-- are we still overlapping?
			IF r_overlap.ind_sid = r.ind_sid AND r_overlap.region_sid = r.region_sid AND r.period_start_dtm < r_overlap.period_end_dtm THEN
				IF r.changed_by_sid!=3 OR r.source_id IS NOT NULL THEN
					v_keep:='K';
				ELSE
					v_keep:='';
					IF v_to_delete IS NOT NULL THEN
						v_to_delete := v_to_delete || ',';
					END IF;		
					v_to_delete := v_to_delete || r.val_id;
				END IF;
				v_output:=v_output||'/'||r.val_id||v_keep;--||'|'||r.period_start_dtm||'|'||r.period_end_dtm||'|'||r.val_number||CHR(10);
				v_overlap_sum := v_overlap_sum + r.val_number;
			ELSE 
				-- we always clean up the numbers since if they were manually entered or imported then they'll be marked for keeping
				-- and won't get deleted
				IF v_overlap_sum != r_overlap.val_number THEN
					v_fixed := 0;
					IF r_overlap.changed_by_sid!=3 OR r_overlap.source_id IS NOT NULL THEN
						-- we must keep the overlap number
						NULL;
					ELSE
						-- we can safely delete the overlap number
						Indicator_Pkg.SetValue(in_act_id, r_overlap.ind_sid, r_overlap.region_sid, r_overlap.period_start_dtm, r_overlap.period_end_dtm,
							NULL, 0, 0, NULL, NULL, NULL, 0, NULL, v_set_val_id);
						v_fixed := 1; -- we fixed it  
					END IF;
					-- delete each of the numbers in v_to_delete - if if wanted to keep it, then it won't be in here
					FOR r_delete IN c_delete(v_to_delete) 
					LOOP
						Indicator_Pkg.SetValue(in_act_id, r_delete.ind_sid, r_delete.region_sid, r_delete.period_start_dtm, r_delete.period_end_dtm,
							NULL, 0, 0, NULL, NULL, NULL, 0, NULL, v_set_val_id);
					END LOOP;
					IF INSTR(v_output, 'K') = 0 THEN
						v_fixed := 1; -- we fixed it
					END IF;
					IF v_fixed = 0 THEN
						DBMS_OUTPUT.PUT_LINE('Must be fixed manually:'||v_output);
						v_problem_count := v_problem_count + 1;
					ELSE
						v_solved_count := v_solved_count + 1;
					END IF;
				END IF;
				v_overlap := FALSE;
			END IF;
		END IF;		
		r_last := r;
	END LOOP;
	DBMS_OUTPUT.PUT_LINE('running region recalc...');
	region_pkg.AggregateTree(in_act_id, v_app_sid);
	DBMS_OUTPUT.PUT_LINE('done: '||v_solved_count|| ' overlaps found of which '||v_problem_count||' are unresolvable automatically');
	DBMS_OUTPUT.PUT_LINE('please recalc stored calculated indicators now');
END;