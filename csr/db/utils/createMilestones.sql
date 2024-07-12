DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_deliverables_sid	security_pkg.T_SID_ID;
	v_deliverable_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAdmin('&&1');
	v_act := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	-- create sec obj 
	BEGIN
		securableobject_pkg.createso(v_act, v_app_sid, security_pkg.SO_CONTAINER, 'Deliverables', v_deliverables_sid);
	EXCEPTION
		WHEN Security_Pkg.DUPLICATE_OBJECT_NAME THEN
			v_deliverables_sid := securableobject_pkg.GetSidFromPath(v_act, v_app_sid, 'Deliverables');
	END;
	BEGIN
		-- Setup progression methods
		insert into progression_method (progression_method_id, label) values (milestone_pkg.PROG_METH_MANUAL, 'Manual');
		insert into progression_method (progression_method_id, label) values (milestone_pkg.PROG_METH_PENDING_TRACKER, 'Pending Tracker');
		insert into progression_method (progression_method_id, label) values (milestone_pkg.PROG_METH_DUE_DATES, 'Due Dates');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore if already inserted 
	END;
	BEGIN
		-- Create a delvierable
		deliverable_pkg.CreateDeliverable(v_act, v_app_sid, '2009 Report', '1 jan 2009', '1 jan 2010', v_deliverable_sid);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_deliverable_sid := securableobject_pkg.GetSidFromPath(v_act, v_deliverables_sid, '2009 Report');
	END;
	DBMS_OUTPUT.PUT_LINE(v_deliverable_sid);
	
	-- assign approval stpes
	insert into approval_step_milestone (milestone_sid, approval_step_id)
		select milestone_sid, approval_step_id
		   from (
			select milestone_sid
			  from milestone
			 where progression_method_Id =0
			   and deliverable_sid =v_deliverable_sid
			)m, (
				select approval_step_id
				  from approval_step
				 minus
				select approval_step_id
				  from  approval_step_milestone
			)a;
END;
/
commit;
exit
