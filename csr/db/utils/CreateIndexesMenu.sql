prompt Enter host:
define host='&&1'

declare
    v_act_id                security.security_pkg.T_ACT_ID;
    v_parent_menu_sid       security.security_pkg.T_SID_ID;
    v_id                    number(10);
    v_cnt					number(10);
begin
    user_pkg.logonadmin('&&host');
    v_act_id := SYS_CONTEXT('SECURITY','ACT');
    v_parent_menu_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.getApp,'menu/indexes');
    for r in (
        select sid_id
          from security.securable_object
         where parent_sid_id = v_parent_menu_sid
           and name like 'csr_text_overview_overview_%'
    )
    loop
        security.securableobject_pkg.deleteso(v_act_id, r.sid_id);
    end loop;
    SELECT COUNT(*) 
      INTO v_cnt
      FROM security.securable_object
     WHERE parent_sid_id = v_parent_menu_sid;
    -- all modules
    for r in (
        select sm.module_root_sid, lower(so.name) name, rownum rn, sm.label
          from csr.section_module sm
          join security.securable_object so on sm.module_root_sid = so.sid_id
         order by sm.label
    )
    loop
        security.menu_pkg.CreateMenu(v_act_id, v_parent_menu_sid,
            'csr_text_overview_overview_'||r.name, 
            r.label, 
            '/csr/site/text/overview/overview.acds?moduleSid='||r.module_root_sid, 
            v_cnt + r.rn, null, v_id);
	end loop;
    -- check all section items are added properly
    FOR r IN (
        SELECT s.section_sid
          FROM csr.section_module sm
            JOIN csr.section s ON sm.module_root_sid = s.module_root_sid
         WHERE sm.flow_sid IS NOT NULL
           AND s.flow_item_id IS NULL
    )
    LOOP
        csr.flow_pkg.AddSectionItem(r.section_sid, v_id);
    END LOOP;    
end;
/