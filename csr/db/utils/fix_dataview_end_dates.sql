declare
	v_end date;
	v_now date := sysdate;
begin
	for r in (
		select app_sid,dataview_sid,start_dtm,period_set_id,period_interval_id from csr.dataview where end_Dtm is null order by app_sid 
	)
	loop	
		if r.period_interval_id=4 then
			v_end := add_months(trunc(v_now, 'YEAR'), 12);
		elsif r.period_interval_id=2 then
			v_end := add_months(trunc(v_now, 'Q'), 3);
		elsif r.period_interval_id = 1 then
			v_end := add_months(trunc(v_now, 'MON'), 1);
		elsif r.period_interval_id = 3 then
			v_end := trunc(v_now, 'Q');
			if v_end = trunc(v_now, 'YEAR') then
				v_end := add_months(v_end, 6);
			else
				v_end := add_months(v_end, 3);
			end if;
		end if;
		--dbms_output.put_line('app '||r.app_sid||', dataview '||r.dataview_sid||', period_interval_id '||r.period_interval_id||', end '||
		--	to_char(v_end, 'yyyy-MM-dd'));
		update csr.dataview set end_dtm = v_end where dataview_sid = r.dataview_sid and app_sid = r.app_sid;
	end loop;
end;
/
