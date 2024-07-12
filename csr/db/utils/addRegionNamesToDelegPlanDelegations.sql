define host='&&1'

declare
    v_cnt    number(10) := 0;
begin
	security.user_pkg.logonadmin('&host');
	update csr.deleg_plan set name_template ='{REGION} - {NAME}';
    for r in (
        select delegation_sid, csr.delegation_pkg.ConcatDelegationRegions(delegation_sid)||' - '||replace(name,' [TEMPLATE]','') name
          from csr.delegation
         start with delegation_sid in (select maps_to_root_deleg_sid from csr.deleg_plan_deleg_region_deleg)
        connect by prior delegation_sid = parent_sid
    )
    loop    
        update csr.delegation set name = r.name where delegation_sid = r.delegation_sid;
        v_cnt := v_cnt + 1;
    end loop;
    dbms_output.put_line(v_cnt||' items fixed');
end;
/