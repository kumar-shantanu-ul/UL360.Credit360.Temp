--Please update version.sql too -- this keeps clean builds in sync
define version=2653
@update_header

update csr.reporting_period set end_dtm = add_months(start_dtm, 12) where end_dtm=start_dtm;
alter table csr.reporting_period add constraint ck_reporting_period_dates check (end_dtm > start_dtm);

@../reporting_period_body

@update_tail
