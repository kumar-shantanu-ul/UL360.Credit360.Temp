-- Please update version.sql too -- this keeps clean builds in sync
define version=48
@update_header



BEGIN
	-- users
	FOR r IN (
		SELECT t.trash_sid, so_name FROM csr_user u, trash t WHERE user_name IS NULL AND u.csr_user_sid = t.trash_sid
	)
    LOOP
		UPDATE csr_user SET user_NAME = r.so_name WHERE csr_user_sid = r.trash_sid;
    END LOOP;
	-- any leftovers
	UPDATE csr_user SET user_name= email WHERE user_name IS NULL;
	-- forms
	FOR r IN (
		SELECT t.trash_sid, so_name FROM form u, trash t WHERE name IS NULL AND u.form_sid = t.trash_sid
	)
    LOOP
		UPDATE form SET NAME = r.so_name WHERE form_sid = r.trash_sid;
    END LOOP;
END;
/


alter table csr_user modify user_name not null;

alter table form modify name not null;

alter table dataview add (pos number(10));

@update_tail
