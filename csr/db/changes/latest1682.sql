-- Please update version.sql too -- this keeps clean builds in sync
define version=1682
@update_header

update csr.pct_ownership set start_dtm = trunc(start_dtm, 'MON') where start_dtm != trunc(start_dtm, 'MON');
update csr.pct_ownership set end_dtm = trunc(end_dtm, 'MON') where end_dtm != trunc(end_dtm, 'MON');
alter table csr.pct_ownership drop constraint ck_pct_ownership_dates;
alter table csr.pct_ownership add constraint ck_pct_ownership_dates check 
(start_dtm = trunc(start_dtm, 'MON') and (end_dtm is null or (end_dtm = trunc(end_dtm, 'MON') and end_dtm > start_dtm)));

@update_tail
