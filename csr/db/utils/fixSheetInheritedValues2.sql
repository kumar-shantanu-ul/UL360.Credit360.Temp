-- fixes up duff sheet_inherited_value data2

set serveroutput on

/*
declare
	v_cnt number;
begin
	select count(*)
	  into v_cnt
	  from user_tables where table_name='XX_SIV_FIX';
	  
	if v_cnt = 0 then
		execute immediate 'create table xx_siv_fix (sheet_value_id number(10), old_val_number number, new_val_number number, old_entry_val_number number, new_entry_val_number number)';
	end if;
end;
/
*/
	
declare
	v_skip 	boolean;
begin
	delete from xx_siv_fix;
	
    for c in (select host from customer where host='&&1') loop
    	begin
        	user_pkg.logonadmin(c.host);
        	v_skip := false;
        exception 
        	when security_pkg.object_not_found then
        		security_pkg.debugmsg('skipping host with no website: '||c.host);
		        dbms_output.put_line('skipping host with no website: '||c.host);
        		v_skip := true;
        end;

		if not v_skip then
			for cs in (
                select distinct sheet_id, lvl
                  from (select s.sheet_id, level lvl
					   	  from delegation d, sheet s
					     where s.app_sid = d.app_sid and s.delegation_sid = d.delegation_sid
					           start with d.parent_sid = d.app_sid
					           connect by prior d.app_sid = d.app_sid and prior d.delegation_sid = d.parent_sid)
			  	  order by lvl desc) loop

				for r in (
					select * 
					  from (
						select -- 0 = indivisible (average), 1 = divisible (sum), 2 = indivisible (last_period) - we use MIN since we already figured out the last period in the inner query
					    	   child_sheet_value_id, child_val_number, child_entry_val_number, 
							   CASE divisible WHEN 0 THEN avg(sum_val_number) WHEN 1 THEN SUM(sum_val_number) WHEN 2 THEN MIN(sum_last_val_number) END val_number,
							   CASE divisible WHEN 0 THEN avg(sum_entry_val_number) WHEN 1 THEN SUM(sum_entry_val_number) WHEN 2 THEN MIN(sum_last_entry_val_number) END entry_val_number
					  	  from (select child_sheet_value_id, child_val_number, child_entry_val_number, 
					                   sheet_id, ind_sid, divisible, aggregate, aggregate_to_region_sid, 
					                   SUM(val_number) sum_val_number, SUM(entry_val_number) sum_entry_val_number,
									   SUM(last_val_number) sum_last_val_number, SUM(last_entry_val_number) sum_last_entry_val_number,
					                   is_regional_aggregation
								  from (select svc.sheet_value_id child_sheet_value_id, svc.val_number child_val_number, svc.entry_val_number child_entry_val_number, 
										       case when svp.val_number = 0 then null else svc.val_number/svp.val_number end ratio,
										       pdr.aggregate_to_region_sid, svp.start_dtm, svp.end_dtm, i.aggregate, i.divisible,  i.ind_sid, svp.sheet_id,
										       CASE WHEN pdr.region_sid != pdr.aggregate_to_region_sid THEN 1 ELSE 0 END is_regional_aggregation,
										       -- if we're not aggregating then use the value WITHOUT taking pct_ownership into account since this will get reapplied WHEN we store it
										       CASE WHEN pdr.region_sid = pdr.aggregate_to_region_sid THEN svp.val_number ELSE svp.actual_val_number END val_number,
										       CASE WHEN pdr.region_sid = pdr.aggregate_to_region_sid THEN svp.entry_val_number ELSE svp.entry_val_number * region_pkg.GetPctOwnership(svp.ind_sid, svp.region_sid, svp.start_dtm)  END entry_val_number,
										       -- figure out the "last_val_number" stuff here in case that's how we're aggregating
										       FIRST_VALUE(CASE WHEN pdr.region_sid = pdr.aggregate_to_region_sid THEN svp.val_number ELSE svp.actual_val_number END) 
										       	OVER (PARTITION BY sp.sheet_id, svp.ind_sid, i.divisible, pdr.aggregate_to_region_sid, pdr.region_sid ORDER BY svp.start_dtm DESC) last_val_number,
										       FIRST_VALUE(CASE WHEN pdr.region_sid = pdr.aggregate_to_region_sid THEN svp.entry_val_number ELSE svp.entry_val_number * region_pkg.GetPctOwnership(svp.ind_sid, svp.region_sid, svp.start_dtm) END) 
										       	OVER (PARTITION BY sp.sheet_id, svp.ind_sid, i.divisible, pdr.aggregate_to_region_sid, pdr.region_sid ORDER BY svp.start_dtm desc) last_entry_val_number
										  from sheet_inherited_value siv, sheet_value_converted svc, sheet_value_converted svp, delegation_region pdr, sheet sp, ind i
										 where siv.app_sid = svp.app_sid and siv.app_sid = svc.app_sid
										   and siv.sheet_value_id = svc.sheet_value_id
										   and siv.inherited_value_id = svp.sheet_value_id
										   and svp.app_sid = sp.app_sid and svp.sheet_id = sp.sheet_id
										   and sp.app_sid = pdr.app_sid and sp.delegation_sid = pdr.delegation_sid
										   and svp.app_sid = pdr.app_sid and svp.region_sid = pdr.region_sid
										   and i.app_sid = svp.app_sid and i.ind_sid = svp.ind_sid
										   and sp.sheet_id = cs.sheet_id)
					   			 group by child_sheet_value_id, child_val_number, child_entry_val_number, sheet_id, ind_sid, divisible, aggregate, is_regional_aggregation, aggregate_to_region_sid)
					   		 group by child_sheet_value_id, child_val_number, child_entry_val_number, sheet_id, ind_sid, divisible, aggregate, is_regional_aggregation, aggregate_to_region_sid)
				   	   where child_val_number != val_number) loop

					insert into xx_siv_fix (sheet_value_id, old_val_number, new_val_number, old_entry_val_number, new_entry_val_number)
					values (r.child_sheet_value_id, r.child_val_number, r.val_number, r.child_entry_val_number, r.entry_val_number);

					dbms_output.put_line('fixing '||r.child_sheet_value_id||' from '||r.child_val_number||' to '||r.val_number);
					update sheet_value
					   set val_number = r.val_number, entry_val_number = r.entry_val_number
					 where sheet_value_id = r.child_sheet_value_id;

					update val
					   set val_number = r.child_val_number, entry_val_number = r.entry_val_number
					 where source_type_id = 1 and source_id = r.child_sheet_value_id;
					if sql%rowcount > 0 then
						dbms_output.put_line('fixed '||sql%rowcount||' rows in val');
					end if;
				end loop;
			end loop;
	        security_pkg.setapp(null);
		end if;        
    end loop;
end;
/
