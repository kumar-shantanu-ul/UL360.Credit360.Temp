-- Please update version.sql too -- this keeps clean builds in sync
define version=2905
define minor_version=3
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
-- Special case of a current duplicate in Mattel
	UPDATE csr.qs_campaign 
	   SET name = 'Sustainability Employee Engagement - Q1 &'||' Q2 - 2013' 
	 WHERE qs_campaign_sid = 18043518
	   AND app_sid = 10411153
	   AND app_sid IN (SELECT app_sid FROM csr.customer WHERE LOWER(host) = 'mattel.credit360.com');

--update all SOs to match campaign names across all clients
	FOR r IN (
		SELECT c.host, qsc.name campaign_name, so.name so_name, qsc.qs_campaign_sid
		  FROM csr.qs_campaign qsc
		  JOIN security.securable_object so ON qsc.qs_campaign_sid = so.sid_id
		  JOIN csr.customer c ON c.app_sid = qsc.app_sid
		 WHERE LOWER(qsc.name) != LOWER(so.name)
		 ORDER BY c.host
	) LOOP
		security.user_pkg.LogonAdmin(r.host);

		security.securableobject_pkg.RenameSO(security.security_pkg.GetACT, r.qs_campaign_sid, r.campaign_name);
	END LOOP;
	security.user_pkg.LogonAdmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../campaign_body

@update_tail
