-- Please update version.sql too -- this keeps clean builds in sync
define version=3263
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- Remove duplicate urjanet auto_imp_fileread_ftp records from hyatt/jmfamily clients.
DECLARE
	v_max NUMBER;
BEGIN
	security.user_pkg.logonadmin();
	FOR c in (SELECT app_sid, host FROM csr.customer WHERE name IN ('hyatt.credit360.com', 'JM Family'))
	LOOP
		security.user_pkg.logonadmin(c.host);
    
		FOR r in (
			SELECT UNIQUE l.app_sid, l.ftp_profile_id, MAX(l.auto_imp_fileread_ftp_id) fileread_ftp_id
			  FROM csr.auto_imp_fileread_ftp l
			  JOIN csr.auto_imp_fileread_ftp r ON 
				   l.auto_imp_fileread_ftp_id != r.auto_imp_fileread_ftp_id AND
				   l.app_sid = r.app_sid AND 
				   l.ftp_profile_id = r.ftp_profile_id AND
				   l.payload_path = r.payload_path AND
				   l.file_mask = r.file_mask
			 GROUP BY l.app_sid, l.ftp_profile_id
		)
		LOOP
			--dbms_output.put_line(c.host ||' App '||r.app_sid||' Id '||r.ftp_profile_id||', DELETE all but '||r.fileread_ftp_id);
			DELETE FROM csr.auto_imp_fileread_ftp
			 WHERE app_sid = r.app_sid AND ftp_profile_id = r.ftp_profile_id AND auto_imp_fileread_ftp_id != r.fileread_ftp_id;
		END LOOP;
    
	security.user_pkg.logonadmin();
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg

@../automated_import_body
@../meter_monitor_body

@update_tail
