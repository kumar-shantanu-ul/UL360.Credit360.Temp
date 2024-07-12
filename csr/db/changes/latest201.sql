-- Please update version.sql too -- this keeps clean builds in sync
define version=201
@update_header

begin
	insert into ind_list (ind_sid)
	    select v.val_id 
	      from val v, ind i, region r, val_change vc
	     where v.ind_sid = i.ind_sid and vc.val_change_id = v.last_val_change_id
	           and v.region_sid = r.region_sid and i.app_sid != r.app_sid;
	
	delete
	  from stored_calc_job 
	 where trigger_val_change_id in (select val_change_id from val_change where val_id in (select ind_sid from ind_list));
	
	delete from val_change where val_id in (select ind_sid from ind_list);
	
	delete from val where val_id in (select ind_sid from ind_list);
	
	commit;
end;
/

@update_tail
