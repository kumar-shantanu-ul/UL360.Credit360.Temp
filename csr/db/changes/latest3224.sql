-- Please update version.sql too -- this keeps clean builds in sync
define version=3224
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
	security.user_pkg.logonadmin;

	INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
	SELECT fsth.app_sid, fsth.flow_sid, 'campaigns.campaign_pkg.ApplyCampaignScoresToSupplier', fsth.label
	  FROM csr.flow_state_trans_helper fsth
	 WHERE lower(fsth.helper_sp) = 'csr.campaign_pkg.applycampaignscorestosupplier'
	   AND NOT EXISTS (
		   SELECT NULL
		     FROM csr.flow_state_trans_helper fsth2
			WHERE fsth2.app_sid = fsth.app_sid
			  AND fsth2.flow_sid = fsth.flow_sid 
			  AND lower(fsth2.helper_sp) = 'campaigns.campaign_pkg.applycampaignscorestosupplier'
	   )
	 GROUP BY fsth.app_sid, fsth.flow_sid, lower(fsth.helper_sp), fsth.label;

	INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
	SELECT fsth.app_sid, fsth.flow_sid, 'campaigns.campaign_pkg.ApplyCampaignScoresToProperty', fsth.label
	  FROM csr.flow_state_trans_helper fsth
	 WHERE lower(fsth.helper_sp) = 'csr.campaign_pkg.applycampaignscorestoproperty'
	     AND NOT EXISTS (
		   SELECT NULL
		     FROM csr.flow_state_trans_helper fsth2
			WHERE fsth2.app_sid = fsth.app_sid
			  AND fsth2.flow_sid = fsth.flow_sid 
			  AND lower(fsth2.helper_sp) = 'campaigns.campaign_pkg.applycampaignscorestoproperty'
	   )
	 GROUP BY fsth.app_sid, fsth.flow_sid, lower(fsth.helper_sp), fsth.label;

	UPDATE csr.flow_state_transition
	   SET helper_sp = 'campaigns.campaign_pkg.ApplyCampaignScoresToSupplier'
	 WHERE lower(helper_sp) = 'csr.campaign_pkg.applycampaignscorestosupplier';

	UPDATE csr.flow_state_transition
	   SET helper_sp = 'campaigns.campaign_pkg.ApplyCampaignScoresToProperty'
	 WHERE lower(helper_sp) = 'csr.campaign_pkg.applycampaignscorestoproperty';

	-- clear old references
	DELETE FROM csr.flow_state_trans_helper
	 WHERE lower(helper_sp) = 'csr.campaign_pkg.applycampaignscorestosupplier';

	DELETE FROM csr.flow_state_trans_helper
	 WHERE lower(helper_sp) = 'csr.campaign_pkg.applycampaignscorestoproperty';

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
