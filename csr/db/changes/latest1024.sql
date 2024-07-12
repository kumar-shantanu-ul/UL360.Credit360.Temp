-- Please update version.sql too -- this keeps clean builds in sync
define version=1024
@update_header

alter table chem.cas modify ( name varchar2(4000) );

@update_tail
