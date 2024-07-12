-- Please update version.sql too -- this keeps clean builds in sync
define version=53
@update_header


CREATE TABLE donations.BUDGET_FIX AS (select * from donations.budget);
CREATE TABLE donations.CUSTOMER_DEFAULT_EXRATE_FIX AS (select * from donations.customer_default_exrate);

-- make it nullable first
alter table donations.budget modify (exchange_rate  number(10,4) null);
-- set values to null
update donations.budget set exchange_rate = null;
-- increase precision
alter table donations.budget modify (exchange_rate number(10,8) );

-- make nullable
alter table donations.customer_default_exrate modify (exchange_rate  number(10,4) null);
-- set values to null
update donations.customer_default_exrate set exchange_rate = null;
-- increase precision
alter table donations.customer_default_exrate modify (exchange_rate number(10,8) );

-- copy old values
BEGIN
for r in (select budget_id, exchange_rate from donations.budget_fix) LOOP
	update donations.budget set exchange_rate = r.exchange_rate where budget_id = r.budget_id;
END LOOP;

for r in (select currency_code, app_sid, exchange_rate from donations.CUSTOMER_DEFAULT_EXRATE_FIX)
LOOP
	update donations.customer_default_exrate set exchange_rate = r.exchange_rate where currency_code = r.currency_code and app_sid = r.app_sid;
END LOOP;
end;
/

-- make columns not nullable again
alter table donations.budget modify (exchange_rate number(10,8) not null);
alter table donations.customer_default_exrate modify (exchange_rate number(10,8) not null );

@../budget_pkg
@../currency_pkg


@update_tail
