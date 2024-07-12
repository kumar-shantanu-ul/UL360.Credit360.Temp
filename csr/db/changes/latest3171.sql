-- Please update version.sql too -- this keeps clean builds in sync
define version=3171
define minor_version=0
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
BEGIN
	security.user_pkg.LogonAdmin;
	
	-- for all apps with duplicate default frames, get the highest alert frame id that has a body set up
	FOR r IN (
		SELECT af.app_sid, MAX(af.alert_frame_id) alert_frame_id_to_keep
		  FROM csr.alert_frame af
		  JOIN csr.alert_frame_body afb ON af.app_sid = afb.app_sid AND af.alert_frame_id = afb.alert_frame_id
		 WHERE af.name = 'Default'
		   AND af.app_sid IN (
			SELECT app_sid
			  FROM csr.alert_frame
			 WHERE name = 'Default'
			 GROUP BY app_sid
			HAVING COUNT(*) > 1
		  )
		 GROUP BY af.app_sid
	) LOOP
		-- trash all other frames that don't have the body set up
		FOR d IN (
			SELECT af.alert_frame_id alert_frame_id_to_trash
			  FROM csr.alert_frame af
			  LEFT JOIN csr.alert_frame_body afb ON af.app_sid = afb.app_sid AND af.alert_frame_id = afb.alert_frame_id
			 WHERE af.app_sid = r.app_sid
			   AND af.name = 'Default'
			   AND afb.alert_frame_id IS NULL
		) LOOP
			UPDATE csr.qs_campaign
			   SET frame_id = r.alert_frame_id_to_keep
			 WHERE app_sid = r.app_sid
			   AND frame_id = d.alert_frame_id_to_trash;

			UPDATE csr.alert_template
			   SET alert_frame_id = r.alert_frame_id_to_keep
			 WHERE app_sid = r.app_sid
			   AND alert_frame_id = d.alert_frame_id_to_trash;
		
			DELETE FROM csr.alert_frame
			 WHERE alert_frame_id = d.alert_frame_id_to_trash
			   AND app_sid = r.app_sid;
		END LOOP;
	END LOOP;
END;
/



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_body

@update_tail
