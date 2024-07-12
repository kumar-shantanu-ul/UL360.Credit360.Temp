-- Please update version.sql too -- this keeps clean builds in sync
define version=2963
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	security.user_pkg.logonadmin;
	
	--remove duplicate records before applying UC
	FOR r IN(
		SELECT to_company_sid, to_user_sid, MIN(recipient_id) min_recipient_id, count(*) count
		  FROM chain.recipient
		 GROUP by to_company_sid, to_user_sid
		HAVING COUNT(*) > 1
	)
	LOOP
		UPDATE chain.message_recipient
		   SET recipient_id = r.min_recipient_id
		 WHERE recipient_id IN(
			SELECT recipient_id
			  FROM chain.recipient
			 WHERE NVL(to_company_sid, 0) = NVL(r.to_company_sid, 0)
			   AND NVL(to_user_sid, 0) = NVL(r.to_user_sid, 0)
			   AND recipient_id <> r.min_recipient_id
		 );
	
		 DELETE FROM chain.recipient
		  WHERE NVL(to_company_sid, 0) = NVL(r.to_company_sid, 0)
			AND NVL(to_user_sid, 0) = NVL(r.to_user_sid, 0)
			AND recipient_id <> r.min_recipient_id;
			 
		 IF SQL%rowcount <> r.COUNT - 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Error removing duplicates for company sid:'||r.to_company_sid||' and user sid:'||r.to_user_sid);
		 END IF;
		 
	END LOOP;
END;
/

ALTER TABLE chain.recipient ADD CONSTRAINT UC_RECIPIENT	UNIQUE (TO_COMPANY_SID, TO_USER_SID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_link_pkg

@../chain/chain_link_body
@../chain/scheduled_alert_body
@../chain/message_body

@update_tail
