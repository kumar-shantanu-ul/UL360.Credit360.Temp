-- Please update version.sql too -- this keeps clean builds in sync
define version=280
@update_header

-- add 'h' things to ind_window -- this really needs fixing up as it's just nonsense (having period etc -- should just
-- use the columns in the IND table
insert into ind_window (ind_sid, upper_bracket, lower_bracket, period, comparison_offset, app_sid) 
	select ind_sid, upper_bracket, lower_bracket, 'h', comparison_offset, app_sid from (
		select row_number() over (partition by ind_sid order by period) rn, app_sid, ind_sid,
			period, upper_bracket, lower_bracket, comparison_offset 
		  from ind_window
		 where ind_sid not in (select ind_sid from ind_window where period='h')
		) 
	where rn = 1;
		
INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('System management', 0);

commit;

@..\csr_data_body
		
@update_tail
