DECLARE
	v_imp_session_sid	security_pkg.T_SID_ID;
	CURSOR c IS 
		SELECT * FROM IMP_CONFLICT WHERE imp_sessioN_sid=v_imp_session_sid;
	CURSOR cNew(in_imp_conflict_id IMP_CONFLICT.imp_conflict_id%TYPE) IS
	  -- we use MIN/MAX because the file_sid or the region / ind is arbitrary, i.e. it's a conflict, so we don't care which one we go for
	  SELECT SUM(iv.VAL * NVL(iv.conversion_factor,1)) VAL, start_dtm, end_dtm, MAX(file_sid) file_sid, imp_session_sid, MIN(imp_ind_id) imp_ind_id, MIN(imp_region_id) imp_region_id
	    FROM IMP_CONFLICT_VAL ICV, IMP_VAL_MAPPED iv
	   WHERE IMP_CONFLICT_ID = in_imp_conflict_id
	     AND iv.imp_val_id = icv.imp_val_id 
	   GROUP BY start_dtm, end_dtm, imp_session_sid, ind_sid, region_sid;
	rNew cNew%ROWTYPE;
    CURSOR cToDelete(in_imp_conflict_id IMP_CONFLICT.imp_conflict_id%TYPE) IS
    	SELECT imp_val_id FROM IMP_CONFLICT_VAL WHERE IMP_CONFLICT_ID = in_imp_conflict_id;
    rToDelete	cToDelete%ROWTYPE;
BEGIN
	v_imp_session_sid := &&1;
	FOR r IN c
	LOOP
		OPEN cNew(r.imp_conflict_id);
		FETCH cNew INTO rNew;
        -- grab a list of stuff to delete
        OPEN cToDelete(r.imp_conflict_id);
		-- delete the conflict (need to do this first because of integrity constraints)
		DELETE FROM IMP_CONFLICT_VAL WHERE imp_conflict_id = r.imp_conflict_id;
		DELETE FROM IMP_CONFLICT WHERE imp_conflict_id = r.imp_conflict_id;
		-- delete the conflicting values
        WHILE TRUE 
        LOOP
        	FETCH cToDelete INTO rToDelete;
            EXIT WHEN cToDelete%NOTFOUND;
            DELETE FROM IMP_VAL WHERE imp_val_id = rToDelete.imp_Val_id;
        END LOOP;
        CLOSE cToDelete;
		-- insert a new value which represents the sum of the conlficts
		INSERT INTO IMP_VAL 
			(imp_val_id, IMP_IND_ID, IMP_REGION_ID, Unknown, START_DTM, END_DTM, VAL, CONVERSION_FACTOR, FILE_SID, IMP_SESSION_SID)
		VALUES
			(imp_val_id_seq.NEXTVAL, rNew.imp_ind_id, rNew.imp_region_id, NULL, rNew.start_dtm, rNew.end_dtm, rNew.VAL, NULL, rNew.file_sid, rNew.imp_session_sid);
		CLOSE cNew;
	END LOOP;
END;


/
COMMIT;
EXIT
