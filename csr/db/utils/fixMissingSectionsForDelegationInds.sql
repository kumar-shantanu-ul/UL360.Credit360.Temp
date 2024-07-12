declare
   v_section_key varchar2(256);
   v_check_next boolean default false;
begin
   raise_application_error('check it first!!!');
   for r in (
     select * from delegation_ind where delegation_sid in (
     select delegation_sid
      from delegation_ind
       where delegation_sid in (select delegation_sid from delegation where app_sid=3287544)
       group by delegation_sid having count(distinct section_key)>0) order by delegation_sid,pos) loop
    if r.section_key is null then
      update delegation_ind
         set section_key = v_section_key
       where delegation_sid = r.delegation_sid and ind_sid = r.ind_sid ;
       v_check_next := true;
    end if;
    if v_check_next and r.section_key is not null then
      if v_section_key <> r.section_key and r.description not like 'SECTION %' then
        raise_application_error(-20001, 'following section key mismatch for '||r.delegation_sid||' and '||r.ind_sid);
      end if;
      v_check_next := false;
    end if;
    if r.section_key is not null then
      v_section_key := r.section_key;
    end if;
  end loop;
end;
/