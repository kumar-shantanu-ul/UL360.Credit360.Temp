DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_pct				NUMBER := .25;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	SELECT app_sid
	  INTO v_app_sid
	  FROM customer
	 WHERE host = '&&1';
	FOR r IN (
		-- don't update csr/indicators or if inactive (i.e. probably in trash - often stuff in trash on old sites has no 'alter schema' permission set)
		SELECT ind_sid FROM ind WHERE app_sid = v_app_sid AND active = 1 AND parent_sid != app_sid
	)
    LOOP
		indicator_pkg.setWindow(v_act, r.ind_sid, 'y', 1-v_pct, 1+v_pct);
		indicator_pkg.setWindow(v_act, r.ind_sid, 'q', 1-v_pct, 1+v_pct);
		indicator_pkg.setWindow(v_act, r.ind_sid, 'm', 1-v_pct, 1+v_pct);    
    END LOOP;
end;
/
