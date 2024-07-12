-- Please update version.sql too -- this keeps clean builds in sync
define version=461
@update_header
 
-- this has gone missing somewhere
declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from user_indexes 
	 where index_name in ('IDX_VAL_LAST_VAL_CHANGE', 'IDX_VAL_LAST_VAL_CHANGE_ID');
	if v_exists = 0 then
		execute immediate 'create index idx_val_last_val_change on val(app_sid, last_val_change_id) tablespace indx';
	end if;
end;
/

@update_tail
