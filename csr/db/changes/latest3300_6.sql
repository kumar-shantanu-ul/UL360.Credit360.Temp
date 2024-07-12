-- Please update version.sql too -- this keeps clean builds in sync
define version=3300
define minor_version=6
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
DECLARE
	v_pos					NUMBER;
	v_card_id				chain.card.card_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter';

	FOR r IN (
		SELECT cus.host
		  FROM (
			SELECT app_sid
			  FROM chain.card_group_card
			 WHERE card_group_id = 54
			 GROUP BY app_sid
			) cg
		  LEFT JOIN (
			SELECT app_sid
			  FROM chain.card_group_card
			 WHERE card_group_id = 54 AND card_id = v_card_id
		  ) c ON c.app_sid = cg.app_sid
		  JOIN security.securable_object so ON so.parent_sid_id = cg.app_sid AND so.name = 'Audits'
		  JOIN csr.customer cus ON cus.app_sid = cg.app_sid
		  JOIN security.website w ON lower(w.website_name) = lower(cus.host)
		 WHERE c.app_sid IS NULL
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		SELECT MAX(position) + 1
		  INTO v_pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 54
		   AND app_sid = security.security_pkg.GetApp;

		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (security.security_pkg.GetApp, 54, v_card_id, v_pos);

		security.user_pkg.Logoff(security.security_pkg.GetAct);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
