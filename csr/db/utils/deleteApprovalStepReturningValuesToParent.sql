set serveroutput on
begin
	user_pkg.logonadmin('xxxxx.credit360.com');
	for r  in (select approval_step_id from approval_step_user where user_sid=xxxxxx) loop
		dbms_output.put_line('deleting '||r.approval_step_id);
		update pending_val 
		   set approval_step_id = (select parent_step_id from approval_step where approval_step_id = r.approval_step_id)
		 where approval_step_id = r.approval_step_id;
		pending_pkg.deleteapprovalstep(sys_context('security','act'), r.approval_step_id);
	end loop;
end;
/
