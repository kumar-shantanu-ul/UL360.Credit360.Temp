-- Please update version.sql too -- this keeps clean builds in sync
define version=311
@update_header
	

-- I added IND_FLAG.REQUIRES_DOCUMENTATION to the DB model, and checked it in
-- without adding it to live. I've now written the code that needs it (and changed
-- the name), so we need to add it if it's not there, OR rename it if it exists already.
DECLARE
	v_cnt NUMBER(10);
BEGIN
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM user_tab_columns 
	 WHERE table_name = 'IND_FLAG' 
	   AND COLUMN_NAME = 'REQUIRES_DOCUMENTATION';

	IF v_cnt = 0 THEN
		-- add it
		EXECUTE IMMEDIATE 'ALTER TABLE IND_FLAG ADD REQUIRES_NOTE NUMBER(1, 0) DEFAULT 0 NOT NULL';
	ELSE
		-- rename it
		EXECUTE IMMEDIATE 'ALTER TABLE IND_FLAG RENAME COLUMN REQUIRES_DOCUMENTATION TO REQUIRES_NOTE';
	END IF;
END;
/

@../csr_data_pkg
@../indicator_pkg
@../indicator_body
@../sheet_body

-- patch dt
update ind_flag set requires_note = 1 where (description like '%(please specify in note)%' or description like '%(bitte%')
   and app_sid in (
		select app_sid from customer where host in ('telekom-internal.credit360.com','c360.telekom.de','c360-test.telekom.de')
   );

@update_tail
