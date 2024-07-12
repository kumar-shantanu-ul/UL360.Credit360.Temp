declare
	v_cnt	number(10) := 0;
begin
	user_pkg.logonadmin('kws.credit360.com');
	for r in (
		select val_id
		  from val
		 where source_type_id = 1
		   and source_id in (
			select sv.sheet_value_id
			  from delegation d
				join sheet s on d.delegation_sid = s.delegation_sid
				join sheet_value sv on s.sheet_id = sv.sheet_id
			 where d.delegation_sid IN (
				select delegation_sid 
				  from delegation
				 start with delegation_sid = 10767321
			   connect by prior delegation_sid = parent_sid
			 )
		)
	)
	loop
		indicator_pkg.DeleteVal(security_pkg.getact, r.val_id, 'clearing out merged delegaton');
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line(v_cnt ||' deleted');
end;
/
