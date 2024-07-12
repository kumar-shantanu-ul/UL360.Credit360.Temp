-- Please update version.sql too -- this keeps clean builds in sync
define version=29
@update_header

alter table form_allocation_user add (read_only number(1,0) default 0 not null);


-- where data is stored as 1-Oct-2006 01:00, if we truncate it might cause overlaps. so clean up any overlaps
FOR r IN (                
	SELECT vc1.changed_dtm dtm1, vc2.changed_dtm dtm2, vc1.val_id id1, vc2.val_id id2
	  FROM val v1, val v2, val_change vc1, val_change vc2
	 WHERE v1.period_start_dtm - TRUNC(v1.period_start_dtm) != 0
	   AND v1.ind_sid = v2.ind_sid
	   AND v1.region_sid = v2.region_sid
	   AND TRUNC(v1.period_end_dtm) = v2.period_end_dtm
	   AND TRUNC(v1.period_start_dtm) = v2.period_start_dtm
	   AND v1.last_val_change_id = vc1.val_change_id
	   AND v2.last_val_change_id = vc2.val_change_id       
)
LOOP
	IF r.dtm1 < r.dtm2 THEN
		DELETE FROM val WHERE val_id = r.id1;
        --DBMS_OUTPUT.PUT_LINE(r.id1||' val id deleted');
    ELSE
		DELETE FROM val WHERE val_id = r.id2;
        --DBMS_OUTPUT.PUT_LINE(r.id2||' val id deleted');
    END IF;         
END LOOP;

-- adjust any data wheret that is an hour behind i.e. 23:00
-- this is caused by the csrimp thing from what I can see
BEGIN
UPDATE val SET period_start_dtm = TRUNC(period_start_dtm+1) WHERE period_start_dtm - TRUNC(period_start_dtm) != 0;
UPDATE val SET period_end_dtm = TRUNC(period_end_dtm+1) WHERE period_end_dtm - TRUNC(period_end_dtm) != 0;
END;
/

-- csrimp thing sometimes knackers up forms too sometimes by the looks of it           
UPDATE FORM SET start_dtm = TRUNC(start_dtm), end_dtm = TRUNC(end_dtm);
/


 ALTER TABLE customer ADD (
	HOST	VARCHAR2(255),
	SYSTEM_MAIL_ADDRESS	VARCHAR2(255)
);


DECLARE
	v_email	VARCHAR2(255);
	v_account_sid	NUMBER(10);	
	v_outbox_sid	NUMBER(10);
BEGIN
	FOR r IN (
		SELECT so.NAME, c.csr_root_sid 
		  FROM
		  (
			SELECT csr_root_sid, so.parent_sid_id
			  FROM customer c, SECURITY.securable_object so
			 WHERE c.csr_root_sid = so.sid_id
		  )c, SECURITY.securable_object so
		 WHERE c.parent_sid_id = so.sid_id
	    )
	LOOP
		IF LOWER(SUBSTR(r.NAME, LENGTH(r.NAME)-13,14)) = '.credit360.com' THEN
			-- a standard foo.credit360.com
			v_email := SUBSTR(r.NAME, 1, LENGTH(r.NAME)-14)||'@credit360.com';
		ELSE
			-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
			v_email := r.NAME||'@credit360.com';
		END IF;
		UPDATE customer 
	       SET HOST = r.NAME, SYSTEM_MAIL_ADDRESS = v_email 
         WHERE csr_root_sid = r.csr_root_sid;
        -- create mail account
        mail.mail_pkg.createAccount(v_email, 'asda1231das9f0asdj212ed!e32fczxvbi8dj', v_account_sid);
	mail.mail_pkg.createMailbox(v_account_sid, 'Outbox', v_outbox_sid);	
	END LOOP; 
END;
/
commit;




-- check it's using sheet_value_id NOT sheet_id
DECLARE
	v_found	NUMBER(10);
BEGIN
	FOR r IN (
		SELECT val_id, v.ind_sid, v.region_sid, source_id, v.val_number
		  FROM val v, sheet_value sv
		 WHERE source_type_id = 1
           AND v.source_id = sv.sheet_value_Id(+)
           AND (sv.val_number IS NULL OR v.val_number != sv.val_number)
     )
    LOOP
    	-- ok, check for sheet
        BEGIN
			SELECT MAX(sheet_value_id) INTO v_found FROM sheet_value WHERE sheet_id = r.source_id AND ind_sid = r.ind_sid AND region_sid = r.region_sid AND val_number = r.val_number;
        	UPDATE val SET source_id = v_found WHERE val_id = r.val_id; -- fix
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
	        	DBMS_OUTPUT.PUT_LINE('dodgy val_id '||r.val_id);
        END;
    END LOOP;
END;
/


BEGIN
	FOR r IN 
		(SELECT root_mailbox_sid, account_id
		  FROM ACCOUNT
		 WHERE (LOWER(email_address) LIKE 'sergio%' OR LOWER(email_address) LIKE 'sara%' OR LOWER(email_address) LIKE 'james@credit360.com') AND apop_secret ='asda1231das9f0asdj212ed!e32fczxvbi8dj')
    LOOP
        DELETE FROM fulltext_index WHERE account_id = r.account_id;
       	DELETE FROM ACCOUNT WHERE account_id = r.account_Id;
    	DELETE FROM mailbox WHERE mailbox_sid IN (SELECT mailbox_sid FROM mailbox WHERE parent_sid = r.root_mailbox_sid); 
       	DELETE FROM mailbox WHERE mailbox_sid = r.root_mailbox_sid;
    END LOOP;
END;  
/


-- fix bug with wrong source_ids
DECLARE
	v_found	NUMBER(10);
BEGIN
	FOR r IN ( 
		SELECT val_id, v.ind_sid, v.region_sid, source_id, v.val_number
		  FROM val v, sheet_value sv
		 WHERE source_type_id = 1
           AND v.source_id = sv.sheet_value_Id(+)
           AND v.val_number = sv.val_number
           AND (v.region_sid != sv.region_sid
	           OR v.ind_sid != sv.ind_sid)
          )
	LOOP
    	-- must be a sheet_id - find sheet_value_Id
        BEGIN
			SELECT sheet_value_id INTO v_found FROM sheet_value WHERE sheet_id = r.source_id AND ind_sid = r.ind_sid AND region_sid = r.region_sid AND val_number = r.val_number;
        	UPDATE val SET source_id = v_found WHERE val_id = r.val_id; -- fix
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
	        	DBMS_OUTPUT.PUT_LINE('dodgy val_id '||r.val_id);
        END;       
    END LOOP;
END;
/               


-- reset to source_type_id 0 if unknown
UPDATE val SET source_type_id = 0 WHERE source_type_id = 1 AND source_id IS NULL;
commit;





@update_tail
