CREATE OR REPLACE PACKAGE BODY CSR.VAL_PKG AS

FUNCTION GetIntervalFromRange(
	in_start_dtm	IN	VAL.period_start_dtm%TYPE,
	in_end_dtm		IN	VAL.period_end_dtm%TYPE
) RETURN CHAR
AS
	v_days		NUMBER(10);
BEGIN
	v_days := in_end_dtm - in_start_dtm;
	IF v_days>=28 AND v_days<=31 THEN
		RETURN 'm';
	ELSIF v_days=7 THEN
		RETURN 'w';
	ELSIF v_days=1 THEN
		RETURN 'd';
	ELSIF v_days>=89 AND v_days<=93 THEN
		RETURN 'q';
	ELSIF v_days>=181 AND v_days<=185 THEN
		RETURN 'h';
	ELSIF v_days>=364 AND v_days<=366 THEN
		RETURN 'y';
	ELSE
		RETURN NULL;
	END IF;
END;

PROCEDURE GetPeriod(
	in_start_dtm	IN  VAL.period_start_dtm%TYPE,
	in_end_dtm		IN  VAL.period_end_dtm%TYPE,
	in_inc			IN  INTEGER,
	out_start_dtm	OUT VAL.period_start_dtm%TYPE,
	out_end_dtm		OUT VAL.period_end_dtm%TYPE
)
AS
	v_period	CHAR(1);
BEGIN
	v_period := GetIntervalFromRange(in_start_dtm, in_end_dtm);
	IF v_period='m' THEN
		SELECT ADD_MONTHS(TRUNC(in_start_dtm,'MM'), in_inc),
			   ADD_MONTHS(TRUNC(in_start_dtm,'MM'), in_inc+1)
		 INTO out_start_dtm, out_end_dtm FROM DUAL;
	ELSIF v_period='w' THEN
		SELECT TRUNC(in_start_dtm)+in_inc*7,
			   TRUNC(in_end_dtm)+(in_inc+1)*7
		 INTO out_start_dtm, out_end_dtm FROM DUAL;
	ELSIF v_period='d' THEN
		SELECT TRUNC(in_start_dtm)+in_inc,
			   TRUNC(in_end_dtm)+in_inc
		 INTO out_start_dtm, out_end_dtm FROM DUAL;
	ELSIF v_period='q' THEN
		SELECT ADD_MONTHS(TRUNC(in_start_dtm), in_inc*3),
			   ADD_MONTHS(TRUNC(in_start_dtm), (in_inc+1)*3)
		 INTO out_start_dtm, out_end_dtm FROM DUAL;
	ELSIF v_period='h' THEN
		SELECT ADD_MONTHS(TRUNC(in_start_dtm), in_inc*6),
			   ADD_MONTHS(TRUNC(in_start_dtm), (in_inc+1)*6)
		 INTO out_start_dtm, out_end_dtm FROM DUAL;
	ELSIF v_period='y' THEN
		SELECT ADD_MONTHS(TRUNC(in_start_dtm), in_inc*12),
			   ADD_MONTHS(TRUNC(in_start_dtm), (in_inc+1)*12)
		 INTO out_start_dtm, out_end_dtm FROM DUAL;
	ELSE
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_PERIOD_UNRECOGNISED, 'Dates do not fall into a recognised period '||in_start_dtm||' '||in_end_dtm);
	END IF;
END;

/* this is a knock-off of credit360\schema\data\rawvaluenormaliser.cs */
FUNCTION NormaliseToPeriodSpan(
	in_cur					IN	SYS_REFCURSOR,
	in_start_dtm 			IN	DATE,
	in_end_dtm				IN	DATE,
    in_interval_duration	IN	NUMBER DEFAULT 1,
	in_divisibility			IN	NUMBER DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
) RETURN T_NORMALISED_VAL_TABLE
AS
	-- processed data
	v_tbl						T_NORMALISED_VAL_TABLE := T_NORMALISED_VAL_TABLE();
	-- rowset values
	v_row_region_sid            security_pkg.T_SID_ID;
    v_row_start_dtm 	        DATE;
	v_row_end_dtm		        DATE;
    v_row_val                   NUMBER(24,10);
	-- value collation
    v_collate_val               NUMBER(24,10);
    v_collate_val_duration      NUMBER(24,10);
    v_collate_region_sid        security_pkg.T_SID_ID;
    v_collate_start_dtm         DATE;
    v_collate_end_dtm           DATE;
    -- interim stuff
    v_chunk_duration            NUMBER(10);
    v_chunk_start_dtm           DATE;
    v_chunk_end_dtm             DATE;
    v_current_end_dtm           DATE;
BEGIN
    v_collate_start_dtm := in_start_dtm;
    FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val;
    IF in_cur%NOTFOUND THEN
		RETURN v_tbl;
    END IF;
	IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
	END IF;	
    -- DBMS_OUTPUT.PUT_LINE('FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
    --
    <<each_region>>
    WHILE in_cur%FOUND
    LOOP
        v_collate_region_sid := v_row_region_sid;
        -- DBMS_OUTPUT.PUT_LINE('region_sid '||v_collate_region_sid);
        v_collate_start_dtm := in_start_dtm;
        <<each_period>>
        WHILE v_collate_start_dtm < in_end_dtm
        LOOP
            v_collate_end_dtm := ADD_MONTHS(v_collate_start_dtm, in_interval_duration);
            -- DBMS_OUTPUT.PUT_LINE('  period '||v_collate_start_dtm||' -> '||v_collate_end_dtm);
            -- for each period in the period span
            -- eat irrelevant historic data in the data reader
            WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid AND v_row_end_dtm <= v_collate_start_dtm
            LOOP
                FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val;			
				IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
				END IF;	
				-- DBMS_OUTPUT.PUT_LINE('  FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
            END LOOP;

            -- ASSUMPTION: data ends after our seek period start
            v_collate_val := null;
            v_collate_val_duration := 0;
            
            -- collate data for period from cursor
            <<collate_period>>
            WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid AND v_row_start_dtm < v_collate_end_dtm
            LOOP
                -- crop date off either side of our period
                v_chunk_start_dtm := GREATEST(v_collate_start_dtm, v_row_start_dtm);
                v_chunk_end_dtm := LEAST(v_collate_end_dtm, v_row_end_dtm);
				-- DBMS_OUTPUT.PUT_LINE('    chunk '||v_chunk_start_dtm||' -> '||v_chunk_end_dtm);
                -- get duration in days
                v_chunk_duration := v_chunk_end_dtm - v_chunk_start_dtm;
                CASE in_divisibility
                    WHEN csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
                        -- if divisble, then get a proportional value for this period
                        -- DBMS_OUTPUT.PUT_LINE('          v_collate_val = '||v_collate_val);
                        -- DBMS_OUTPUT.PUT_LINE('          v_row_val = '||v_row_val);	
                        -- DBMS_OUTPUT.PUT_LINE('          v_chunk_duration = '||v_chunk_duration);
                        -- DBMS_OUTPUT.PUT_LINE('          row duration = '||(v_row_end_dtm - v_row_start_dtm));
                        v_collate_val := NVL(v_collate_val, 0) + v_row_val * v_chunk_duration / (v_row_end_dtm - v_row_start_dtm);
						-- DBMS_OUTPUT.PUT_LINE('    val = '||v_collate_val);
                    WHEN csr_data_pkg.DIVISIBILITY_LAST_PERIOD THEN
                        -- we want to use the last value for the period
                        -- e.g. Q1, Q2, Q3, Q4 << we take Q4 value
                        v_collate_val := v_row_val;
                    WHEN csr_data_pkg.DIVISIBILITY_AVERAGE THEN
                        -- if not divisible, then average this out over differing periods for val
                        IF v_collate_val_duration + v_chunk_duration = 0 THEN
                            v_collate_val := 0; -- avoid division by 0
                        ELSE
                            v_collate_val := (NVL(v_collate_val,0) * v_collate_val_duration + v_row_val * v_chunk_duration) / (v_collate_val_duration + v_chunk_duration);
                        END IF;
                        v_collate_val_duration := v_collate_val_duration + v_chunk_duration;                    
                END CASE;
                
                -- what next? store this value away...?
                -- DBMS_OUTPUT.PUT_LINE('    check: '||v_collate_end_dtm||' <= '||v_row_end_dtm);
                EXIT collate_period WHEN v_collate_end_dtm <= v_row_end_dtm;
                
                -- DBMS_OUTPUT.PUT_LINE('    fetch more...');
                -- or keep getting more data to build up the new value?
                
                /* get some more data, but swallow anything which starts before the end of the
                   last data we shoved into our overall value for this period.
                   e.g.
                   J  F  M  A  M  J  J  A  (seek period is Jan -> end June)
                   |--------|        |     (used)
                   |     |-----|     |     (discarded) << or throw exception?
                   |        |--------|--|  (used - both parts)
                   |              |--|     (discarded) << or throw exception?
                */
                -- eat_intermediate_data
                v_current_end_dtm := v_row_end_dtm; 
                WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid AND v_row_start_dtm < v_current_end_dtm
                LOOP
                    FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val;			
					IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
						RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
					END IF;	
					-- DBMS_OUTPUT.PUT_LINE('    FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
                END LOOP;

            END LOOP;
		
			-- store
			-- DBMS_OUTPUT.PUT_LINE('    '||v_collate_start_dtm||' -> '||v_collate_end_dtm||' ['||v_collate_region_sid||'] = '||v_collate_val);
			v_tbl.extend;
			v_tbl(v_tbl.COUNT) := T_NORMALISED_VAL_ROW(
				v_collate_region_sid, v_collate_start_dtm, v_collate_end_dtm, v_collate_val);	

            -- DBMS_OUTPUT.PUT_LINE('    fetched all for period, moving to next period, starting '||v_collate_end_dtm);
            
            -- next period
            v_collate_start_dtm := v_collate_end_dtm;            
        END LOOP;
        
        -- DBMS_OUTPUT.PUT_LINE('  periods processed. skip to next region...');
        -- skip to start of next region (if not already at start)
        WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid
        LOOP
            FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val; -- try next row								
			IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
			END IF;	
			-- DBMS_OUTPUT.PUT_LINE('  FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
        END LOOP;        
        -- DBMS_OUTPUT.PUT_LINE('  now processing region_sid '||v_row_region_sid);
    END LOOP;
	
    -- DBMS_OUTPUT.PUT_LINE('done');
	RETURN v_tbl;
END;	

-- XXX: 13P
PROCEDURE GetValueActualAndPrevious(
	in_act_id					IN	security_pkg.t_act_id,
	in_period_start_dtm			IN	val.period_start_dtm%TYPE,
	in_period_end_dtm			IN	val.period_end_dtm%TYPE,
	in_ind_sid					IN 	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_interval					IN 	VARCHAR2, --ind.default_interval%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ val_id, val_number, i.description as ind_description, r.description as region_description, i.ind_sid, r.region_sid, period_start_dtm, period_end_dtm,
		       CASE WHEN in_interval = 'y' THEN (
		        	SELECT val_number 
		        	  FROM val 
		        	 WHERE ind_sid = in_ind_sid 
		        	   AND region_sid = in_region_sid 
		        	   AND period_start_dtm = ADD_MONTHS(TRUNC(in_period_start_dtm,'MM'), -12) 
		        	   AND period_end_dtm = ADD_MONTHS(TRUNC(in_period_end_dtm,'MM'), -12))
		       		WHEN in_interval = 'h' THEN (
		        	SELECT val_number 
		        	  FROM val 
		        	 WHERE ind_sid = in_ind_sid 
		        	   AND region_sid = in_region_sid 
		        	   AND period_start_dtm = ADD_MONTHS(TRUNC(in_period_start_dtm,'MM'), -6) 
		        	   AND period_end_dtm = ADD_MONTHS(TRUNC(in_period_end_dtm,'MM'), -6))
		       		WHEN in_interval = 'q' THEN (
		        	SELECT val_number 
		        	  FROM val 
		        	 WHERE ind_sid = in_ind_sid 
		        	   AND region_sid = in_region_sid 
		        	   AND period_start_dtm = ADD_MONTHS(TRUNC(in_period_start_dtm,'MM'), -3) 
		        	   AND period_end_dtm = ADD_MONTHS(TRUNC(in_period_end_dtm,'MM'), -3))
		       		WHEN in_interval = 'm' THEN (
		        	SELECT val_number 
		        	  FROM val 
		        	 WHERE ind_sid = in_ind_sid 
		        	   AND region_sid = in_region_sid 
		        	   AND period_start_dtm = ADD_MONTHS(TRUNC(in_period_start_dtm,'MM'), -1) 
		        	   AND period_end_dtm = ADD_MONTHS(TRUNC(in_period_end_dtm,'MM'), -1))
		       		 END previous_value
		  FROM val v, v$ind i, v$region r
		 WHERE v.ind_sid = in_ind_sid
		   AND v.region_sid = in_region_sid
		   AND v.period_end_dtm = in_period_end_dtm
		   AND v.period_start_dtm = in_period_start_dtm
		   AND v.ind_sid = i.ind_sid
		   AND v.region_sid = r.region_sid;
END;


PROCEDURE GetAndCompareValue(
	in_act_id					IN	security_pkg.t_Act_id,
	in_period_start_dtm			IN	val.PERIOD_START_DTM%TYPE,
	in_period_end_dtm			IN	val.PERIOD_END_DTM%TYPE,
	in_ind_sid					IN 	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
    in_comparison_val_number	IN 	sheet_value.val_number%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT val_id, val_number, i.description as ind_description, r.description as region_description,
        	   CASE WHEN v.val_number = ROUND(in_comparison_val_number,10) THEN 1 ELSE 0 END values_the_same
		  FROM val v, v$ind i, v$region r
		 WHERE v.ind_sid = in_ind_sid
		   AND v.region_sid = in_region_sid
		   AND v.period_end_dtm = in_period_end_dtm
		   AND v.period_start_dtm = in_period_start_dtm
		   AND v.ind_sid = i.ind_sid
		   AND v.region_sid = r.region_sid;
END;

PROCEDURE GetAggregateDetails(
	in_ind_sid						IN	val.ind_sid%TYPE,
	in_region_sid					IN	val.region_sid%TYPE,
	in_start_dtm					IN	val.period_start_dtm%TYPE,
	in_end_dtm						IN	val.period_end_dtm%TYPE,
	out_val_cur						OUT	SYS_REFCURSOR,
	out_child_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN	
	-- check we have read permission on indicator + region
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;

	-- get this value
	OPEN out_val_cur FOR 
		SELECT /*+ALL_ROWS*/ v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
			   v.val_number, v.error_code, v.source_type_id, v.source_id,
			   v.entry_measure_conversion_id, v.entry_val_number, v.note, v.changed_dtm,
			   v.changed_by_sid
	      FROM val v,
	  		   (SELECT region_sid
	  	          FROM region 
		   	           START WITH region_sid = in_region_sid
	                   CONNECT BY PRIOR parent_sid = region_sid
	             UNION
	            SELECT NVL(link_to_region_sid, region_sid) region_sid
	              FROM region
	             WHERE parent_sid = in_region_sid) r
	     WHERE r.region_sid = v.region_sid
	       AND v.period_end_dtm > in_start_dtm
	       AND v.period_start_dtm < in_end_dtm
	       AND v.ind_sid = in_ind_sid
	     ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm;
	       
	OPEN out_child_cur FOR
		SELECT NVL(link_to_region_sid, region_sid) region_sid,
			   DECODE(link_to_region_sid, NULL, 0, 1) is_link
		  FROM region
		 WHERE parent_sid = in_region_sid;
END;

-- get parent values
PROCEDURE GetParentValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	CURSOR c IS
		SELECT period_start_dtm, period_end_dtm, ind_sid, region_sid 
		  FROM val 
		 WHERE val_id = in_val_id;
	r_vs	c%ROWTYPE;
BEGIN
	-- get basic info about val
	OPEN c;
	FETCH c INTO r_vs;
	
	-- check we have read permission on indicator + region
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_vs.ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_vs.region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ vo.val_id, vo.val_number, vo.error_code,
			   vo.ind_sid, i.description ind_description, i.ind_type,
			   vo.region_sid, rd.description region_description,
			   vo.period_start_dtm, vo.period_end_dtm, 
			   vo.source_type_Id, st.description source_type_description, vo.source_id,
			   CASE 
			     WHEN vo.changed_by_sid = 3 THEN 'System'
				 ELSE NVL(cu.full_name, 'Unknown')
			   END changed_by,
			   changed_dtm, 
			   m.description measure_description,
			   r.lvl,
			   NULL link_to_region_sid, -- to mirror GetChildValues
			   NVL(i.scale, m.scale) ind_scale
	      FROM v$ind i, source_type st, csr_user cu, val vo, measure m,
	  		  (SELECT region_sid, level lvl 
	  	         FROM region 
		   	          START WITH region_sid = r_vs.region_sid
	                  CONNECT BY PRIOR parent_sid = region_sid) r,
			   region_description rd
	     WHERE vo.ind_sid = i.ind_sid
		   AND vo.source_type_id = st.source_type_id
	       AND vo.changed_by_sid = cu.csr_user_sid
		   AND vo.region_sid = r.region_sid 
		   AND vo.ind_sid = r_vs.ind_sid
	       AND vo.period_end_dtm > r_vs.period_start_dtm
	       AND vo.period_start_dtm < r_vs.period_end_dtm
		   AND i.measure_sid = m.measure_sid
		   AND r.lvl > 1
		   AND r.region_sid = rd.region_sid
		   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		 ORDER BY r.lvl DESC, LOWER(rd.description), vo.period_start_dtm;
END;

-- Get child values (those that contributed to an aggregate)
PROCEDURE GetChildValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	CURSOR c IS
		SELECT period_start_dtm, period_end_dtm, ind_sid, region_pkg.ParseLink(region_sid) region_sid
		  FROM val 
		 WHERE val_id = in_val_id;
	r_vs			c%ROWTYPE;
BEGIN
	-- get basic info about val
	OPEN c;
	FETCH c INTO r_vs;
	
	-- check we have read permission on indicator + region
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_vs.ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_vs.region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ vo.val_id, ROUND(vo.val_number * (
				CASE WHEN NVL(i.divisibility, m.divisibility) != csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN 1 
					 WHEN vo.period_end_dtm = vo.period_start_dtm THEN NULL
				 	 ELSE (r_vs.period_end_dtm - r_vs.period_start_dtm) / (vo.period_end_dtm - vo.period_start_dtm)
				 	 END), 10) val_number,
			   vo.error_code,
			   vo.ind_sid, i.description ind_description, i.ind_type,
			   vo.region_sid, r.description region_description,
			   vo.period_start_dtm, vo.period_end_dtm, 
			   vo.source_type_Id, st.description source_type_description, vo.source_id,
			   CASE 
			     WHEN vo.changed_by_sid = 3 THEN 'System'
			     ELSE NVL(cu.full_name, 'Unknown')
			   END changed_by,
			   changed_dtm,
			   m.description measure_description,
			   r.link_to_region_sid,
			   NVL(i.scale, m.scale) ind_scale
		  FROM v$ind i, source_type st, csr_user cu, val vo, v$region r, measure m
		 WHERE vo.ind_sid = i.ind_sid
		   AND vo.source_type_id = st.source_type_id
		   AND vo.changed_by_sid = cu.csr_user_sid
		   AND r.parent_sid = r_vs.region_sid
		   AND vo.region_sid = NVL(r.link_to_region_Sid, r.region_sid)
		   AND vo.ind_sid = r_vs.ind_sid
	       AND vo.period_end_dtm > r_vs.period_start_dtm
	       AND vo.period_start_dtm < r_vs.period_end_dtm
		   AND i.measure_sid = m.measure_sid
		   AND (vo.val_number IS NOT NULL OR vo.error_code IS NOT NULL)
		 ORDER BY LOWER(r.description), vo.region_sid, period_start_dtm;
END;


-- get single values
PROCEDURE GetValue(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	in_check_due	IN	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	CURSOR c IS
		SELECT period_start_dtm, period_end_dtm, ind_sid, region_sid
		  FROM val 
		 WHERE val_id = in_val_id;
	r_vs				c%ROWTYPE;
	v_interval	VARCHAR2(10);
	v_due_for_recalc	NUMBER(10);
BEGIN
	-- get basic info about val
	OPEN c;
	FETCH c INTO r_vs;
	IF c%NOTFOUND THEN
		CLOSE c;
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The value with id '||in_val_id||' could not be found');
	END IF;
	CLOSE c;	
	
	v_interval := val_pkg.GetIntervalFromRange(r_vs.period_start_dtm, r_vs.period_end_dtm);
	
	-- check we have read permission on indicator + region
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_vs.ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r_vs.region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data');
	END IF;
	
	v_due_for_recalc := 0;
	IF in_check_due = 1 THEN
        BEGIN
            SELECT 1
              INTO v_due_for_recalc
              FROM DUAL
             WHERE EXISTS (SELECT *
                             FROM val_change_log vcl
                            WHERE vcl.app_sid = SYS_CONTEXT('SECURITY', 'APP')
                              AND vcl.ind_sid = r_vs.ind_sid
                              AND vcl.start_dtm < r_vs.period_end_dtm
                              AND vcl.end_dtm > r_vs.period_start_dtm);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
	END IF;
	
	-- get this value
	OPEN out_cur FOR 
		SELECT /*+ALL_ROWS*/ v.val_id, v.val_number,
			   v.ind_sid, i.description ind_description, i.ind_type,
			   v.region_sid, r.description region_description,
			   v.period_start_dtm, v.period_end_dtm, 
			   v_interval interval, v.note,
			   v.source_type_Id, st.description source_type_description, v.source_id,
			   CASE 
			     WHEN v.changed_by_sid = 3 THEN 'System'
			     ELSE NVL(cu.full_name, 'Unknown')
			   END changed_by,
			   changed_dtm,
			   m.description measure_description,
			   v_due_for_recalc due_for_recalc,
			   error_code,
			   NVL(i.scale, m.scale) ind_scale
	      FROM val v, v$ind i, source_type st, csr_user cu, v$region r, measure m
		 WHERE v.ind_sid = i.ind_sid
		   AND v.source_type_id = st.source_type_id
		   AND v.changed_by_sid = cu.csr_user_sid
		   AND v.val_id = in_val_id
		   AND v.region_sid = r.region_sid
		   AND i.measure_sid = m.measure_sid;
END;		


PROCEDURE RollbackToValChangeId(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_val_change_id		IN  val_change.val_change_id%TYPE,
	out_val_id				OUT VAL.val_id%TYPE
)
AS
	CURSOR c IS
		SELECT ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, note, source_id, source_type_id,
			   entry_measure_conversion_id, entry_val_number
		  FROM val_change 
		 WHERE val_change_id = in_val_change_id;
	r	c%ROWTYPE;	
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%FOUND THEN
		Indicator_Pkg.SetValue(in_act_id, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, r.val_number,
			0, r.source_type_id, r.source_id, r.entry_measure_conversion_id, r.entry_val_number, 
			0, r.note, out_val_id);	
	END IF;	
END;


PROCEDURE GetBaseDataForInd(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	in_from_dtm			IN VAL.period_start_dtm%TYPE,
	in_to_dtm			IN VAL.period_end_dtm%TYPE,
	in_order_by			IN	VARCHAR2, -- Note: not used
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    -- CH: Changed to only get the regions which this user has access to see. FB:19.
    -- RK: removed as this is horribly slow though and GetBaseDataForRegion ought to be changed too (strictly speaking)
    -- TODO: alter this (and GetBaseDataForRegion) not to use IsAccessAllowed but to check from user's region start points downwards?
    -- Reason I've not done this now is because there's an oddity around some users have a null mount point sid which
    -- needs some thinking about.
	OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/ r.description, v.period_start_dtm, TO_CHAR(v.period_start_dtm,'Mon yyyy') period_start_dtm_fmt, 
			   TO_CHAR(v.period_end_dtm,'Mon yyyy') period_end_dtm_fmt, v.period_end_dtm, v.val_id, v.val_number, 
			   changed_by_sid, NVL(cu.full_name,'System Administrator') full_name, changed_dtm, TO_CHAR(changed_dtm,'dd Mon yyyy') changed_dtm_fmt, v.source_id, v.source_type_id, st.description source_type,
			   'region' type, region_pkg.INTERNAL_GetRegionPathString(r.region_sid) path, v.note, v.error_code
		  FROM val v, v$region r, ind i, csr_user cu, source_type st  
		 WHERE v.ind_sid = in_ind_sid 
		  -- AND v.source_type_id !=5 
		   AND (v.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL) AND v.period_end_dtm > in_from_dtm
		   AND v.region_sid = r.region_sid 
		   AND v.ind_sid = i.ind_sid 
           AND st.source_type_id = v.source_type_id 
		   AND cu.csr_user_sid = v.changed_by_sid
           --AND security_pkg.sql_IsAccessAllowedSID(in_act_id, r.region_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY v.period_start_dtm, r.description;
END;

PROCEDURE GetBaseDataForIndFiltered(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by_region 			IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
        SELECT /*+ALL_ROWS*/ r.description, v.period_start_dtm, v.period_end_dtm, v.val_id, v.val_number, 
			   changed_by_sid, NVL(cu.full_name,'System Administrator') full_name, changed_dtm, v.source_id source_id,
			   v.source_type_id, st.description source_type, 'region' type, region_pkg.INTERNAL_GetRegionPathString(r.region_sid) path, 
			   v.note, v.error_code, i.measure_sid, v.entry_measure_conversion_id, v.entry_val_number, 
			   mc.description entry_units, m.description units, NVL(i.format_mask, m.format_mask) format_mask,
			   r.region_sid, i.ind_sid, i.description indicator, cu.csr_user_sid,
			   CASE WHEN EXISTS (SELECT 1 FROM val_file WHERE val_id = v.val_id) THEN 1 ELSE 0 END attachment
		  FROM val v, v$region r, v$ind i, csr_user cu, source_type st, measure m, measure_conversion mc 
		 WHERE v.ind_sid = in_ind_sid
		   AND v.app_sid = mc.app_sid(+) AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		   AND (v.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL) AND v.period_end_dtm > in_from_dtm
		   AND v.app_sid = r.app_sid AND v.region_sid = r.region_sid 
		   AND v.app_sid = i.app_sid AND v.ind_sid = i.ind_sid 
           AND st.source_type_id = v.source_type_id 
		   AND i.ind_type != csr_data_pkg.IND_TYPE_CALC -- don't return values if it's a calc (FB14111)
		   AND cu.app_sid = v.app_sid AND cu.csr_user_sid = v.changed_by_sid
		   AND (in_get_aggregates = 1 OR v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
		   AND v.region_sid IN (SELECT region_sid 
		   						  FROM region 
		   						  	   START WITH region_sid = in_filter_by_region
		   						  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid)
            
		 ORDER BY v.period_start_dtm, r.description;
END;

PROCEDURE GetBaseDataForRegion(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_from_dtm			IN VAL.period_start_dtm%TYPE,
	in_to_dtm			IN VAL.period_end_dtm%TYPE,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ i.description, v.period_start_dtm, TO_CHAR(v.period_start_dtm,'Mon yyyy') period_start_dtm_fmt, 
			   TO_CHAR(v.period_end_dtm,'Mon yyyy') period_end_dtm_fmt, v.period_end_dtm, v.val_id, v.val_number, 
			   changed_by_sid, NVL(cu.full_name,'System Administrator') full_name, changed_dtm, TO_CHAR(changed_dtm,'dd Mon yyyy') changed_dtm_fmt, v.source_id, v.source_type_id, st.description source_type,
			   'indicator' type, indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid) path, v.note, v.error_code
		  FROM val v, region r, v$ind i, csr_user cu, source_type st
		 WHERE v.region_sid = in_region_sid 
		  -- AND v.source_type_id !=5 
		   AND (v.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL) AND v.period_end_dtm > in_from_dtm
		   AND v.region_sid = r.region_sid 
		   AND v.ind_sid = i.ind_sid 
           AND st.source_type_id = v.source_type_id 
		   AND cu.app_sid = v.app_sid AND cu.csr_user_sid = v.changed_by_sid
		 ORDER BY v.period_start_dtm, i.description;
END;

PROCEDURE GetBaseDataForRegionFiltered(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by_ind   				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ i.description, v.period_start_dtm, v.period_end_dtm, v.val_id, v.val_number,
			   changed_by_sid, NVL(cu.full_name,'System Administrator') full_name, changed_dtm, v.source_id source_id, 
			   st.description source_type, v.source_type_id, 'indicator' type, indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid) path, 
			   v.note, v.error_code, i.measure_sid, v.entry_measure_conversion_id, v.entry_val_number, 
			   mc.description entry_units, m.description units, NVL(i.format_mask, m.format_mask) format_mask,
			   r.region_sid, i.ind_sid, r.description region, cu.csr_user_sid,
			   CASE WHEN EXISTS (SELECT 1 FROM val_file WHERE val_id = v.val_id) THEN 1 ELSE 0 END attachment
		  FROM val v, v$region r, v$ind i, csr_user cu, source_type st, measure m, measure_conversion mc  
		 WHERE v.region_sid = in_region_sid 
		   AND v.app_sid = mc.app_sid(+) AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		   AND (v.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL) AND v.period_end_dtm > in_from_dtm
		   AND v.app_sid = r.app_sid AND v.region_sid = r.region_sid 
		   AND v.app_sid = i.app_sid AND v.ind_sid = i.ind_sid 
           AND st.source_type_id = v.source_type_id 
		   AND i.ind_type != csr_data_pkg.IND_TYPE_CALC -- don't return values if it's a calc (FB14111)
		   AND cu.app_sid = v.app_sid AND cu.csr_user_sid = v.changed_by_sid
		   AND (in_get_aggregates = 1 OR v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
		   AND v.ind_sid IN (SELECT ind_sid 
		   					   FROM ind 
		   					   		START WITH ind_sid = in_filter_by_ind 
		   					   		CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid)
		 ORDER BY v.period_start_dtm, i.description;
END;

-- used by raw data view
PROCEDURE GetBaseData(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_or_region	IN VARCHAR2,
	in_sid				IN security_pkg.T_SID_ID,
	in_from_dtm			IN VAL.period_start_dtm%TYPE,
	in_to_dtm			IN VAL.period_end_dtm%TYPE,
	in_order_by			IN	VARCHAR2, -- Note: not used
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF in_ind_or_region = 'region' THEN
		GetBaseDataForRegion(in_act_id, in_sid, in_from_dtm, in_to_dtm, in_order_by, out_cur);
	ELSE
		GetBaseDataForInd(in_act_id, in_sid, in_from_dtm, in_to_dtm, in_order_by, out_cur);
	END IF;
END;

PROCEDURE GetBaseDataForIndFiltered2(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by_region 			IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
			   v.val_number, v.error_code, v.source_type_id, v.source_id,
			   v.entry_measure_conversion_id, v.entry_val_number, v.note, v.changed_dtm,
			   v.changed_by_sid
		  FROM val v
		 WHERE v.ind_sid = in_ind_sid
		   AND (v.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL)
		   AND v.period_end_dtm > in_from_dtm
		   AND (in_get_aggregates = 1 OR v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
		   AND (in_get_stored_calc_values = 1 OR v.source_type_id != csr_data_pkg.SOURCE_TYPE_STORED_CALC)
		   AND v.region_sid IN (SELECT region_sid 
		   						  FROM region 
		   						  	   START WITH region_sid = in_filter_by_region
		   						  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid)
		 ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm;
END;

PROCEDURE GetBaseDataForRegionFiltered2(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by_ind   				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
			   v.val_number, v.error_code, v.source_type_id, v.source_id,
			   v.entry_measure_conversion_id, v.entry_val_number, v.note, v.changed_dtm,
			   v.changed_by_sid
		  FROM val v
		 WHERE v.region_sid = in_region_sid 
		   AND (v.period_start_dtm < in_to_dtm OR in_to_dtm IS NULL)
		   AND v.period_end_dtm > in_from_dtm
		   AND (in_get_aggregates = 1 OR v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR)
		   AND (in_get_stored_calc_values = 1 OR v.source_type_id != csr_data_pkg.SOURCE_TYPE_STORED_CALC)
		   AND v.ind_sid IN (SELECT ind_sid 
		   					   FROM ind 
		   					   		START WITH ind_sid = in_filter_by_ind 
		   					   		CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid)
		 ORDER BY v.ind_sid, v.region_sid, v.period_start_dtm;
END;

PROCEDURE GetBaseDataFiltered2(
	in_ind_or_region				IN	VARCHAR2,
	in_sid							IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by      				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	in_get_stored_calc_values		IN	NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF in_ind_or_region = 'region' THEN
		GetBaseDataForRegionFiltered2(in_sid, in_from_dtm, in_to_dtm, in_filter_by,
			in_get_aggregates, in_get_stored_calc_values, out_cur);
	ELSE
		GetBaseDataForIndFiltered2(in_sid, in_from_dtm, in_to_dtm, in_filter_by,
			in_get_aggregates, in_get_stored_calc_values, out_cur);
	END IF;
END;

PROCEDURE GetBaseDataFiltered(
	in_ind_or_region				IN	VARCHAR2,
	in_sid							IN	security_pkg.T_SID_ID,
	in_from_dtm						IN	val.period_start_dtm%TYPE,
	in_to_dtm						IN	val.period_end_dtm%TYPE,
	in_filter_by      				IN	security_pkg.T_SID_ID,
	in_get_aggregates               IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF in_ind_or_region = 'region' THEN
		GetBaseDataForRegionFiltered(in_sid, in_from_dtm, in_to_dtm, in_filter_by, in_get_aggregates, out_cur);
	ELSE
		GetBaseDataForIndFiltered(in_sid, in_from_dtm, in_to_dtm, in_filter_by, in_get_aggregates, out_cur);
	END IF;
END;

PROCEDURE GetConflictsForInds(
	in_src_ind_sid					IN	security_pkg.T_SID_ID,
	in_dest_ind_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	val.period_start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						IN	val.period_end_dtm%TYPE DEFAULT NULL,
	in_filter_by_region_sid 		IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_src_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_dest_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_filter_by_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	/*	
	s.val_id source_val_id,
	s.val_number source_val_number, s.source_type_id source_type_id, 
	s.period_start_dtm source_start_dtm, s.period_end_dtm source_end_dt
	*/
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ 
			i.description, d.period_start_dtm, d.period_end_dtm, d.val_id, d.val_number, d.error_code,
			d.changed_by_sid, NVL(cu.full_name,'System Administrator') full_name, d.changed_dtm, d.source_id, 
			st.description source_type, d.source_type_id, 'indicator' type, indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid) path, 
			d.note, i.measure_sid, d.entry_measure_conversion_id, d.entry_val_number, 
			mc.description entry_units, m.description units, NVL(i.format_mask, m.format_mask) format_mask, r.description region
			  FROM val s
				JOIN val d 
					ON s.region_sid = d.region_sid
					AND s.period_start_dtm < d.period_end_dtm
					AND s.period_end_dtm > d.period_start_dtm
					AND s.app_sid = d.app_sid
					AND s.ind_sid = in_src_ind_sid
					AND d.ind_sid = in_dest_ind_sid
					AND s.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR					
					AND (in_start_dtm IS NULL OR in_start_dtm < s.period_end_dtm)
					AND (in_end_dtm IS NULL OR in_end_dtm > s.period_start_dtm)
				JOIN v$region r ON s.region_sid = r.region_sid AND s.app_sid = r.app_sid
				JOIN v$ind i ON d.ind_sid = i.ind_sid AND d.app_sid = i.app_sid AND i.ind_type != csr_data_pkg.IND_TYPE_CALC 
				JOIN csr_user cu ON d.changed_by_sid = cu.csr_user_sid
				JOIN source_type st ON st.source_type_id = d.source_type_id 
				LEFT JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_Sid
				LEFT JOIN measure_conversion mc ON d.entry_measure_conversion_id = mc.measure_conversion_id AND d.app_sid = mc.app_sid			
			 WHERE (in_filter_by_region_sid IS NULL
					OR s.region_sid IN (SELECT region_sid 
										   FROM region
										   START WITH region_sid = in_filter_by_region_sid
										 CONNECT BY PRIOR region_sid = parent_sid) 
				)
			  ORDER BY d.period_start_dtm, r.region_sid;
END;

/**
 * Return if an indicator has a value
 * Used in indicator_pkg.IsIndicatorUsed
 */ 
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)RETURN BOOLEAN
AS
BEGIN
	 FOR x IN (SELECT COUNT(*) found 
	             FROM dual 
				WHERE EXISTS(SELECT 1 
				               FROM val 
							  WHERE ind_sid = in_ind_sid)
				)
	LOOP
		 RETURN x.found = 1;
	 END LOOP;
END;

FUNCTION SQL_IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID	
)RETURN NUMBER
AS
BEGIN
	 FOR x IN (SELECT COUNT(*) found 
	             FROM dual 
				WHERE EXISTS(SELECT 1 
				               FROM val 
							  WHERE ind_sid = in_ind_sid)
				)
	LOOP
		 RETURN x.found;
	END LOOP;
END;

PROCEDURE GetFilesForValue(
	in_act_id			IN	security.security_pkg.T_ACT_ID,
	in_val_id			IN	val.val_id%TYPE,
	out_cur_files		OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid			security.security_pkg.T_SID_ID;
	v_ind_sid				security.security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid, ind_sid
	  INTO v_region_sid, v_ind_sid
	  FROM val
	 WHERE val_id = in_val_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur_files FOR
		SELECT v.val_id, r.description region_description,
		       fu.file_upload_sid, fu.filename, fu.mime_type, fu.data
		  FROM val v
		  JOIN val_file vf ON vf.app_sid = v.app_sid AND vf.val_id = v.val_id
		  JOIN file_upload fu ON fu.app_sid = vf.app_sid AND fu.file_upload_sid = vf.file_upload_sid
		  JOIN v$region r ON r.app_sid = v.app_sid AND r.region_sid = v.region_sid
		 WHERE v.val_id = in_val_id;
END;

END;
/
