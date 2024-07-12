PROMPT Host, root delegation sid, new end_dtm (e.g 1 apr 2010)
declare
	v_root_sid	security_pkg.T_SID_ID;
	v_dtm		sheet.start_dtm%TYPE;
	v_is_root	NUMBER(10);
begin
	user_pkg.logonadmin('&&1');
	v_root_sid := &&2;
	v_dtm := '&&3';
	SELECT CASE WHEN app_sid != parent_sid THEN 1 ELSE 0 END
	  INTO v_is_root
	  FROM delegation
	 WHERE delegation_sid = v_root_sid;
	IF v_is_root = 0 THEN
		RAISE_APPLICATION_ERROR(-20001,'Delegation isn''t root deleg');
	END IF;
	for r in (	
		select sheet_id 
		  from sheet 
		 where delegation_sid in (
			select delegation_sid 
			  from delegation 
			 start with delegation_sid = v_root_sid
		   connect by prior delegation_sid = parent_sid
		 ) and start_dtm >=v_dtm
	)
	loop
		sheet_pkg.DeleteSheet(r.sheet_id);	
	end loop;

	update delegation 
	   set end_dtm = v_dtm
	 where delegation_sid in (
			select delegation_sid 
			  from delegation 
			 start with delegation_sid = v_root_sid
		   connect by prior delegation_sid = parent_sid
	 );
end;
/

