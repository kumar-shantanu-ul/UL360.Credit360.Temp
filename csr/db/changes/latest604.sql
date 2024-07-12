-- Please update version.sql too -- this keeps clean builds in sync
define version=604
@update_header

-- backup just in case we need the data
create table csr.broken_pct_ownership_data as
	select * 
	  from csr.pct_ownership
     where start_dtm != trunc(start_dtm) or end_dtm != trunc(end_dtm);

-- fix up hoping for the best
update csr.pct_ownership
   set start_dtm = trunc(start_dtm)
 where start_dtm != trunc(start_dtm);
  
update csr.pct_ownership
   set end_dtm = trunc(end_dtm)
 where end_dtm != trunc(end_dtm);

alter table csr.pct_ownership add constraint ck_pct_ownership_dates check (start_dtm = TRUNC(start_dtm) AND (end_dtm IS NULL OR (end_dtm = TRUNC(end_dtm) AND end_dtm > start_dtm)));

@update_tail
