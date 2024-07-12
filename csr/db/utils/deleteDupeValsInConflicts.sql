-- goes through all conflicts (NB not on a per session basis atm!!) and removes dupe values
DECLARE
	CURSOR c IS 
   		SELECT icv.imp_conflict_id, icv.imp_val_id, iv.val
		  FROM imp_conflict ic, imp_conflict_val icv, imp_val iv
		 WHERE ic.imp_conflict_id = icv.imp_conflict_id
		   AND icv.imp_val_id = iv.imp_val_id  
		 ORDER BY ic.imp_conflict_id;
	r	c%ROWTYPE;
	v_last_imp_conflict_id	imp_conflict.imp_conflict_id%TYPE := -1;
    v_last_val				imp_val.val%TYPE;
    v_different 			boolean := false;
    v_count					integer := 0;
    v_i						integer;
    v_val_ids				IntArray;
    v_remaining				integer;
BEGIN
    v_val_ids := IntArray(NULL);
    v_val_ids.EXTEND(v_val_ids.LIMIT - 1); 
	OPEN c;
	LOOP
    	FETCH c INTO r;        
    	IF c%NOTFOUND OR (v_last_imp_conflict_id != r.imp_conflict_id AND v_last_imp_conflict_id != -1) THEN
        	IF NOT v_different AND v_count > 1 THEN
            	-- delete dupes (leaving 1 remaining in theory)
                FOR v_i IN 2..v_count
                LOOP 
	                --dbms_output.put_line('delete '||TO_CHAR(v_val_ids(v_i)));
					DELETE FROM IMP_CONFLICT_VAL WHERE imp_val_id = v_val_ids(v_i);
                    DELETE FROM IMP_VAL WHERE imp_val_id = v_val_ids(v_i);
                    -- can we delete the conflict?
                    SELECT COUNT(*) INTO v_remaining 
                      FROM IMP_CONFLICT_VAL
                     WHERE imp_conflict_id = v_last_imp_conflict_id;
                    IF v_remaining = 1 THEN
	                    --dbms_output.put_line('delete conflict '||TO_CHAR(v_last_imp_conflict_id));
                        DELETE FROM IMP_CONFLICT_VAL WHERE IMP_CONFLICT_ID = v_last_imp_conflict_id;
                        DELETE FROM IMP_CONFLICT WHERE IMP_CONFLICT_ID = v_last_imp_conflict_id;
                    END IF;
                END LOOP;
            END IF;
            v_count := 0;
            v_different := false;
        	EXIT WHEN c%NOTFOUND;			        
        END IF;
        --
        IF v_last_imp_conflict_id = r.imp_conflict_id AND v_last_imp_conflict_id != -1 AND r.val != v_last_val THEN
        	v_different := true;
        END IF;
        --
        v_count := v_count + 1;
		v_val_ids(v_count) := r.imp_val_id; -- array is 1 based
    	v_last_imp_conflict_id := r.imp_conflict_id;
        v_last_val	:= r.val;
   	END LOOP;
END;
