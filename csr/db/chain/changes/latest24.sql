define version=24
@update_header

alter table customer_options add sched_alerts_enabled number(1) default 0 not null;

begin
	begin
		user_pkg.logonadmin('maersk.credit360.com');
		update customer_options set sched_alerts_enabled = chain_pkg.ACTIVE where app_sid = SYS_CONTEXT('SECURITY', 'APP');
	exception
		when others then
			null;
	end;	
end;
/

@../scheduled_alert_body
-- alter table customer_options drop column sched_alerts_enabled;

@update_tail
