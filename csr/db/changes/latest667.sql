-- Please update version.sql too -- this keeps clean builds in sync
define version=667
@update_header

-- we have to add this as we reference it in places where a user might not have permission on the trash
ALTER TABLE csr.CUSTOMER ADD (
    TRASH_SID                        NUMBER(10, 0)     
);

BEGIN
	FOR r IN (
		SELECT app_sid, so.sid_id trash_sid_id FROM customer c
			LEFT JOIN security.securable_object so ON c.app_sid = so.parent_sid_id AND so.name='Trash'
	)
	LOOP
		UPDATE csr.customer 
		   SET trash_sid = r.trash_sid_id
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/


ALTER TABLE csr.CUSTOMER MODIFY TRASH_SID NOT NULL;

@..\csr_data_body
@..\region_body

@update_tail
