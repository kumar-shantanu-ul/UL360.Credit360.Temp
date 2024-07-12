-- Please update version.sql too -- this keeps clean builds in sync
define version=1802
@update_header

grant select,insert,update,delete on csrimp.dataview_trend to web_user;
grant select on csr.dataview_trend_id_seq to csrimp;
grant insert on csr.dataview_trend to csrimp;

@update_tail
