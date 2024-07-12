-- Please update version.sql too -- this keeps clean builds in sync
define version=19
@update_header

-- secobjs with dupe names - due to move not checking - MUST FIX IN SECURITY!
DECLARE
BEGIN
	FOR r IN (
		select parent_sid, lower(name) name
		  from ind
		 group by parent_sid, lower(name)
		having count(*)>1
	    )
	LOOP
    	UPDATE ind SET name = name || '2' WHERE ind_sid = (select max(ind_sid) from ind where parent_sid = r.parent_sid and lower(name)= r.name);
	END LOOP;
END;
/

-- test to see if all done - should return 0
		select count(*) from
        (Select parent_sid, lower(name)
		  from ind
		 group by parent_sid, lower(name)
		having count(*)>1);



declare
	v_act varchar(38);
	v_sid number(36);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
    for r in (        
      select sid_Id from security.securable_object where class_id = 727034
      minus
      select dataview_sid sid_Id from dataview
	) LOOP   
		securableobject_pkg.deleteso(v_act,r.sid_id);
    END LOOP;
end;
/


-- fix up wrong column type
ALTER TABLE ERROR_LOG 
drop CONSTRAINT RefSOURCE_TYPE196;

ALTER TABLE ERROR_LOG 
drop CONSTRAINT PK123 ;

alter table error_log add ERROR_LOG_ID2 NUMBER(10);

update error_log set error_log_id2 = error_log_id;

alter table error_log drop column error_log_id;

alter table error_log rename column error_log_id2 to error_log_id;

ALTER TABLE ERROR_LOG MODIFY(error_Log_id NOT NULL);

alter table error_log add  CONSTRAINT PK123 PRIMARY KEY (ERROR_LOG_ID);

ALTER TABLE ERROR_LOG ADD CONSTRAINT RefSOURCE_TYPE196 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID)
;

@update_tail
