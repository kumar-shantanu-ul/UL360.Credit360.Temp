-- Please update version.sql too -- this keeps clean builds in sync
define version=327
@update_header

update val set period_start_dtm = trunc(period_start_dtm + 12/24) where trunc(period_start_dtm)!=period_start_dtm;
update val set period_end_dtm = trunc(period_end_dtm + 12/24) where trunc(period_end_dtm)!=period_end_dtm;
alter table val add constraint ck_val_start_date check (period_start_dtm = trunc(period_start_dtm));
alter table val add constraint ck_val_end_date check (period_end_dtm = trunc(period_end_dtm));

/*
There's more bizarre stuff in there:

select app_sid,extract(day from period_start_dtm) day,count(*) from
val where extract(day from period_start_dtm)!=1
group by app_sid,extract(day from period_start_dtm)
order by app_sid,day;

Not sure what to do with the existing  data though.
*/

@update_tail
