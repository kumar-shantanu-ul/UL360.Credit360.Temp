DECLARE
	in_imp_session_sid	security_pkg.T_SID_ID := 1559588;
BEGIN
	FOR r IN (
		select icv.imp_val_id, ic.imp_conflict_id 
		  from imp_conflict ic, imp_conflict_val icv
		 where ic.imp_session_sid = in_imp_session_sid
		   and ic.imp_conflict_id = icv.imp_conflict_id 
		   and accept = 0)
	LOOP
	    DELETE FROM IMP_CONFLICT_VAL WHERE imp_val_id = r.imp_val_id;
        DELETE FROM IMP_VAL WHERE imp_val_id = r.imp_val_id;
	END LOOP;
    -- resolve conflicts with 1 thing left
	FOR r IN (    
		select ic.imp_conflict_id 
		  from imp_conflict ic, imp_conflict_val icv
		 where ic.imp_session_sid = in_imp_session_sid
		   and ic.imp_conflict_id = icv.imp_conflict_id
         group by ic.imp_conflict_id
        having count(icv.imp_val_id) = 1)
    LOOP
	    DELETE FROM IMP_CONFLICT_VAL WHERE IMP_CONFLICT_ID = r.imp_conflict_id;
        DELETE FROM IMP_CONFLICT WHERE IMP_CONFLICT_ID = r.imp_conflict_id;
    END LOOP;    
END;