-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	
	security.user_pkg.logonadmin;
	
	UPDATE csr.flow_alert_class
	   SET on_save_helper_sp = 'flow_pkg.OnCreateCampaignFlow'
	 WHERE flow_alert_class = 'campaign';

	FOR t IN (
		SELECT fst.app_sid, fst.flow_sid, fst.flow_state_transition_id, fst.helper_sp, fst.verb
		  FROM csr.flow f
		  JOIN csr.flow_state_transition fst ON f.flow_sid = fst.flow_sid AND f.app_sid = fst.app_sid
		 WHERE fst.lookup_key = 'SUBMIT'
		   AND fst.helper_sp IS NULL
		   AND f.flow_alert_class = 'campaign'
		   AND EXISTS(
			SELECT 1
			  FROM csr.qs_campaign qsc
			  JOIN csr.quick_survey qs ON qsc.survey_sid = qs.survey_sid AND qsc.app_sid = qs.app_sid
			  JOIN csr.score_type st ON qs.score_type_id = st.score_type_id AND qs.app_sid = st.app_sid
			 WHERE qsc.flow_sid = f.flow_sid
			   AND st.applies_to_regions = 1
		  )
	)
	LOOP
		-- Ensure we have the helper sp registered for the flow
		BEGIN
			INSERT INTO csr.flow_state_trans_helper
				(app_sid, flow_sid, helper_sp, label)
			VALUES
				(t.app_sid, t.flow_sid, 'csr.campaign_pkg.ApplyCampaignScoresToProperty','Update property scores from campaign');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		-- Add the helper sp to the state transistion
		UPDATE csr.flow_state_transition
		   SET helper_sp = 'csr.campaign_pkg.ApplyCampaignScoresToProperty'
		 WHERE app_sid = t.app_sid
		   AND flow_state_transition_id = t.flow_state_transition_id;
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../campaign_pkg

@../flow_body
@../campaign_body
@../audit_helper_body

@update_tail
