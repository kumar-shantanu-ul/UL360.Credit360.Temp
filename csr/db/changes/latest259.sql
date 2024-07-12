-- Please update version.sql too -- this keeps clean builds in sync
define version=259
@update_header

begin 
	for r in (select 1 from user_tab_columns where nullable='N' and table_name='VAL_CHANGE' and column_name='VAL_ID') loop
		execute immediate 'alter table val_change modify val_id null';
	end loop;
end;
/

update val_change
   set val_id = null
 where val_id not in (select val_id from val);

/*
update val_change
   set val_id = null
 where val_id in (select val_id from val_change
 				   minus
 				  select val_id from val);
*/
				 
ALTER TABLE VAL_CHANGE ADD CONSTRAINT RefVAL1049
    FOREIGN KEY (APP_SID, VAL_ID)
    REFERENCES VAL(APP_SID, VAL_ID) ON DELETE SET NULL
;



@update_tail
