-- Please update version.sql too -- this keeps clean builds in sync
define version=1197
@update_header

GRANT SELECT,REFERENCES ON aspen2.translation_set TO csr WITH GRANT OPTION;

declare
	v_sql varchar2(4000);
	v_tag varchar2(4000);
	v_first boolean;
begin
	security.user_pkg.logonadmin;
	for rc in (select distinct app_sid from csr.snapshot) loop
		security.security_pkg.setapp(rc.app_sid);
		
		for r in (select s.name, (select count(*) from csr.snapshot_tag_group stg where stg.app_sid = rc.app_sid and stg.name = s.name) num_tag_groups
					from csr.snapshot s, all_tables at
				   where s.app_sid = rc.app_sid
				     and at.owner = 'CSR'
				     and at.table_name = 'SS_'||s.name) loop
			
			if r.num_tag_groups > 0 then
				
				v_first := true;

				for t in (select tag_group_id
							from csr.snapshot_tag_group
						   where app_sid = rc.app_sid and name = r.name) loop
					if v_first then
						v_tag := '(tgm.tag_group_id = '||t.tag_group_id;
					else
						v_tag := v_tag || ' OR tgm.tag_group_id = '||t.tag_group_id;
					end if;
				end loop;
				v_tag := v_tag || ')';
			
				v_sql :=
'create or replace view csr.v$ss_'||r.name||' as
	select r.description, p.label period_label, v.*, rt.tag, rt.tag_id
	  from ss_'||r.name||' v, v$region r, ss_'||r.name||'_period p,
           (select rt.region_sid, t.tag_id, t.tag
              from region_tag rt, tag_group_member tgm, tag t
             where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and 
                   rt.tag_id = tgm.tag_id and '||v_tag||') rt
	 where v.region_sid = r.region_sid
	   and v.period_id = p.period_id
       and r.region_sid = rt.region_sid(+)';
			else
				v_sql := 
'create or replace view csr.v$ss_'||r.name||' as
	select r.description, p.label period_label, v.*, null tag, null tag_id
	  from ss_'||r.name||' v, v$region r, ss_'||r.name||'_period p
	 where v.region_sid = r.region_sid
	   and v.period_id = p.period_id';
	   		end if;
			--dbms_output.put_line(v_sql);
	   		execute immediate v_sql;
		end loop;
	end loop;
end;
/
       
@update_tail
