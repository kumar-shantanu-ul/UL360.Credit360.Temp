define v_aps_id=13933460;

exec user_pkg.logonadmin('worldbank.credit360.com');
delete from pending_val_log
 where pending_val_id in (
	select pending_val_id 
	  from pending_val 
	 where approval_step_Id in (
		select approval_step_id 
		  from approval_step 
		 start with approval_step_id = &&v_aps_id 
	   connect by prior approval_step_id = parent_step_id
	 )
);
delete from pending_val_variance
 where pending_val_id in (
	select pending_val_id 
	  from pending_val 
	 where approval_step_Id in (
		select approval_step_id 
		  from approval_step 
		 start with approval_step_id = &&v_aps_id 
	   connect by prior approval_step_id = parent_step_id
	 )
);
delete from pending_val 
 where approval_step_Id in (
	select approval_step_id 
	  from approval_step 
	 start with approval_step_id = &&v_aps_id 
   connect by prior approval_step_id = parent_step_id
);
exec pending_pkg.deleteapprovalstep(security_pkg.getact, &&v_aps_id);
