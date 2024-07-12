PROMPT Enter Host, regionSid, toplevelDelegationSid
PROMPT e.g. example.credit360.com xxxx yyyy

DECLARE	
    v_is_active			region.active%TYPE;
BEGIN
    security.user_pkg.LogonAdmin('&&1');
	
	--Make sure the region isn't inactive
	SELECT active
		INTO v_is_active
		FROM region
		WHERE region_sid = '&&2';
	
	IF v_is_active = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Region must be active!');
	END IF;
	
	--Find child delegs down the heirarchy
	FOR r in (select * from delegation 
					START WITH delegation_sid = '&&3'
						CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid)
	loop
	  update delegation_region
	  set visibility = 'SHOW'
	  where delegation_sid = r.delegation_sid
	  and region_sid = '&&2';
	end loop;
	
END;
/


commit;
exit
