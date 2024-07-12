BEGIN
	user_pkg.logonadmin('&&1');
	FOR r IN (
		SELECT ind_sid
		  FROM (
			SELECT ind_sid, measure_sid, roll_forward
			  FROM ind 
			 START WITH ind_sid = &&rootIndSid
			CONNECT BY PRIOR ind_sid = parent_sid
		  )
		 WHERE measure_sid IS NOT NULL
		   AND roll_forward = 0
	)
	LOOP
		UPDATE ind SET roll_forward = 1 WHERE ind_sid = r.ind_sid;
		DBMS_OUTPUT.PUT_LINE('doing '||r.ind_sid);
		indicator_pkg.RollForward(r.ind_sid);
	END LOOP;
END;
/