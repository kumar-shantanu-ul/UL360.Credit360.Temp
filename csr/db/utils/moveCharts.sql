
declare
	v_act			security_pkg.T_ACT_ID;
	v_from_sid			security_pkg.T_SID_ID;
	v_new_sid			security_pkg.T_SID_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/emil', 10000, v_act);
	v_from_sid := securableobject_pkg.GetSIDFromPath(v_act, 0, '//aspen/applications/&&host/dataviews');
	v_new_sid := securableobject_pkg.GetSIDFromPath(v_act, 0, '//aspen/applications/&&host/dataviews/2007 charts');
    FOR r IN (
        SELECT dataview_sid FROM dataview WHERE parent_sid = v_from_sid -- AND name like '06 %'
    )
    LOOP
        securableobject_pkg.MoveSO(v_act, r.dataview_sid, v_new_sid);
    END LOOP;
end;
/
