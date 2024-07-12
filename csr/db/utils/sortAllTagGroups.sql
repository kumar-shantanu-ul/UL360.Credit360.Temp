declare
  v_act security_pkg.T_ACT_ID;
begin
  user_pkg.LogonAuthenticatedPath(0,'//builtin/administrator', 1000, v_act);
  for r in (select tag_group_id from tag_group tg, customer c where tg.app_sid = c.app_sid and host='&&1')
  loop
    tag_pkg.SortTagGroupMembers(v_act, r.tag_group_id);
  end loop;
end;
/
