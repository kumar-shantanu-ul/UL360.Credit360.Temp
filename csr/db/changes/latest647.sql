-- Please update version.sql too -- this keeps clean builds in sync
define version=647
@update_header

declare
	v_rp 	csr.RECURRENCE_PATTERN;
	v_cnt	number(10);
begin
	-- monthly
	v_cnt := 0;
	for r in (
		select schedule_xml, delegation_sid from csr.delegation where interval = 'm' and schedule_xml not like '%monthly every-n="1"%' and schedule_xml not like '%monthly>%'
	)
	loop
		v_rp := csr.RECURRENCE_PATTERN(XMLType(r.schedule_xml));
		v_rp.SetRepeatPeriod('monthly');
		update csr.delegation set schedule_xml = v_rp.getClob where delegation_Sid = r.delegation_sid;
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line('fixed '||v_cnt||' monthly');

	-- quarterly
	v_cnt := 0;
	for r in (
		select schedule_xml, delegation_sid from csr.delegation where interval = 'q' and schedule_xml not like '%monthly every-n="3"%'
	)
	loop
		v_rp := csr.RECURRENCE_PATTERN(XMLType(r.schedule_xml));
		v_rp.SetRepeatPeriod('monthly',3);
		update csr.delegation set schedule_xml = v_rp.getClob where delegation_Sid = r.delegation_sid;
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line('fixed '||v_cnt||' quarterly');

	-- half-yearly
	v_cnt := 0;
	for r in (
		select schedule_xml, delegation_sid from csr.delegation where interval = 'h' and schedule_xml not like '%monthly every-n="6"%'
	)
	loop
		v_rp := csr.RECURRENCE_PATTERN(XMLType(r.schedule_xml));
		v_rp.SetRepeatPeriod('monthly',6);
		update csr.delegation set schedule_xml = v_rp.getClob where delegation_Sid = r.delegation_sid;
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line('fixed '||v_cnt||' half-yearly');

	-- annually
	v_cnt := 0;
	for r in (
		select schedule_xml, delegation_sid from csr.delegation where interval = 'y' and schedule_xml not like '%yearly%'
	)
	loop
		v_rp := csr.RECURRENCE_PATTERN(XMLType(r.schedule_xml));
		v_rp.SetRepeatPeriod('yearly');
		update csr.delegation set schedule_xml = v_rp.getClob where delegation_Sid = r.delegation_sid;
		v_cnt := v_cnt + 1;
	end loop;
	dbms_output.put_line('fixed '||v_cnt||' yearly');
end;
/

@update_tail
