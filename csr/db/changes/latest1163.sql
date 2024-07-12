-- Please update version.sql too -- this keeps clean builds in sync
define version=1163
@update_header 

drop sequence ct.region_id_seq;

@update_tail