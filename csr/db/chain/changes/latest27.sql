define version=27
@update_header

create table tmp_force_set_log (
	app_sid		number(10) default SYS_CONTEXT('SECURITY', 'APP'),
	user_sid	number(10) default SYS_CONTEXT('SECURITY', 'SID'),
	company_sid	number(10),
	at_dtm		timestamp(6) default SYSDATE
);

@..\chain_pkg
@..\company_pkg

@..\chain_body
@..\company_body
@..\capability_body

@update_tail
