define version=88
@update_header

ALTER TABLE chain.FILE_UPLOAD ADD (BYTES NUMBER(10, 0));

BEGIN
	UPDATE chain.file_upload o
	   SET bytes = (
	   		SELECT dbms_lob.getlength(data)
	   		  FROM file_upload i
	   		 WHERE i.file_upload_sid = o.file_upload_sid
	   	);
END;
/

ALTER TABLE chain.FILE_UPLOAD MODIFY BYTES NOT NULL;

connect aspen2/aspen2@&_CONNECT_IDENTIFIER;
grant execute on aspen2.filecache_pkg to chain;
connect chain/chain@&_CONNECT_IDENTIFIER;

@..\upload_pkg
@..\upload_body

@update_tail

