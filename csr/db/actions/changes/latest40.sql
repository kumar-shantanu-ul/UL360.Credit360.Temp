-- Please update version.sql too -- this keeps clean builds in sync
define version=40
@update_header

create table duff_task_period_rows as
	select tp.*
	  from task_period tp, (
		    select task_sid, r.region_sid
		      from csr.region r, customer_options co, csr.customer c, (
		        select distinct task_sid, region_sid from task_period
		        minus
		        select task_sid, region_sid from task_region    
		     )x
		     where x.region_sid = r.region_sid
		       and r.app_sid = c.app_sid
		       and c.app_sid = co.app_sid
		       and co.use_actions_v2 = 1
	   )y
	 where tp.task_sid = y.task_sid
	   and tp.region_sid = y.region_sid;


declare
	v_duff_row_cnt	number(10);
begin
	for r in (
		select task_sid, start_dtm, region_sid from duff_task_period_rows
	)
	loop
		delete
		  from task_period_override
		 where task_sid = r.task_sid
	       and start_dtm = r.start_dtm
  		   and region_sid = r.region_sid;
		delete 
          from task_period 
		 where task_sid = r.task_sid
	       and start_dtm = r.start_dtm
  		   and region_sid = r.region_sid;
	end loop;
	--
	select count(*) 
      into v_duff_row_cnt
      from duff_task_period_rows;
	if v_duff_row_cnt = 0 then
        -- clean up the table we created
		execute immediate 'drop table duff_task_period_rows purge';
	else
		dbms_output.put_line('***** ' ||v_duff_row_cnt||' duff rows put into duff_task_period_rows table *****');
	end if;
end;
/


insert into task_region (task_sid, region_sid, use_for_calc)
    select task_sid, r.region_sid, 0
      from csr.region r, customer_options co, csr.customer c, (
        select distinct task_sid, region_sid from task_period
        minus
        select task_sid, region_sid from task_region    
     )x
     where x.region_sid = r.region_sid
       and r.app_sid = c.app_sid
       and c.app_sid = co.app_sid
       and co.use_actions_v2 != 1;

-- XXX: may not be correct, this has already been applied to live so it's just
-- local cleanup though
delete from task_period where (task_sid, region_sid) in
	(select task_sid, region_sid
	   from task_period
	  minus 
	 select task_sid, region_sid
	   from task_region);
	   
ALTER TABLE TASK_PERIOD ADD CONSTRAINT RefTASK_REGION102
    FOREIGN KEY (TASK_SID, REGION_SID)
    REFERENCES TASK_REGION(TASK_SID, REGION_SID)
;

@..\task_body.sql


@update_tail
