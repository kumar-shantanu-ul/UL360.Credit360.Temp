-- Please update version.sql too -- this keeps clean builds in sync
define version=331
@update_header

alter table customer add use_user_sheets number(1,0) default 0 not null;
alter table customer add constraint CK_CUST_USE_USER_SHEETS check (USE_USER_SHEETS IN (0,1));
update customer set use_user_sheets=1 where host='hsbc.credit360.com';

alter table dataview modify end_dtm null;
alter table dataview add USE_UNMERGED          NUMBER(1, 0)      DEFAULT 0 NOT NULL;
alter table dataview add USE_BACKFILL          NUMBER(1, 0)      DEFAULT 0 NOT NULL;
alter table dataview add USE_AGGR_ESTIMATES    NUMBER(1, 0)      DEFAULT 0 NOT NULL;
alter table dataview add USE_PENDING		   NUMBER(1, 0)      DEFAULT 0 NOT NULL;
alter table dataview add SHOW_CALC_TRACE       NUMBER(1, 0)      DEFAULT 0 NOT NULL;
alter table dataview add SHOW_VARIANCE         NUMBER(1, 0)      DEFAULT 0 NOT NULL;

alter table dataview add CONSTRAINT CK_DATAVIEW_USE_UNMERGED CHECK (USE_UNMERGED IN (0,1));
alter table dataview add CONSTRAINT CK_DATAVIEW_USE_BACKFILL CHECK (USE_BACKFILL IN (0,1));
alter table dataview add CONSTRAINT CK_DATAVIEW_USE_AGGR_EST CHECK (USE_AGGR_ESTIMATES IN (0,1));
alter table dataview add CONSTRAINT CK_DATAVIEW_USE_PENDING CHECK (USE_PENDING IN (0,1));
alter table dataview add CONSTRAINT CK_DATAVIEW_SHOW_CALC_TRACE CHECK (SHOW_CALC_TRACE IN (0,1));
alter table dataview add CONSTRAINT CK_DATAVIEW_SHOW_VARIANCE CHECK (SHOW_VARIANCE IN (0,1));

@..\csr_app_body
@..\dataview_pkg
@..\dataview_body
 
@update_tail
