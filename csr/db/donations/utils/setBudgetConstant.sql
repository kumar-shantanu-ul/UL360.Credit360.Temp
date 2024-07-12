declare
	v_budget_id	budget.budget_Id%TYPE := 21; -- set this
	v_val		budget_constant.val%TYPE := 15; -- set this
	v_host		csr.customer.host%TYPE := 'example.credit360.com';
	v_constant_id	NUMBER(10);
begin
	insert into constant (constant_id, lookup_key, app_sid)
		values (constant_id_seq.nextval, 'staff_hourly_rate', 
                  (select app_sid from csr.customer where host=v_host))
		returning constant_id into v_constant_id;
	insert into budget_constant 
		(budget_id, constant_id, val)
	values (v_budget_Id, v_constant_id, v_val);
end;
/
