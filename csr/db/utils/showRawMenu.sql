declare
    v_cur   security_pkg.T_OUTPUT_CUR; 
    v_act	security_pkg.T_ACT_ID;    
    v_sid_id		number(10);	
    v_name			varchar2(255);
    v_so_level		number(10);
    v_description	varchar2(255);
    v_action		varchar2(255);
    v_pos			number(10);
    v_context		number(10);
begin
    user_pkg.logonadmin('&&host');
    user_pkg.LogonAuthenticatedPath(security_pkg.getapp, 'users/&&user', 10000, v_act);	
    security.menu_pkg.GetMenu(security_pkg.getact, securableobject_pkg.getsidfrompath(security_pkg.getact, security_pkg.getapp, 'menu'), v_cur);
    loop
        fetch v_cur INTO v_sid_id, v_name, v_so_level, v_description, v_action, v_pos, v_context;
        exit when v_cur%NOTFOUND;
        dbms_output.put_line(LPAD(' ',(v_so_level-1)*4)||v_name||' ('||v_sid_id||')');
    end loop;
    user_pkg.logoff(security_pkg.GETACT);
end;
/
