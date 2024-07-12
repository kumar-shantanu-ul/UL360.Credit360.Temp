-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=1
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
DECLARE
	v_invsumm_count 		NUMBER;
	v_invsummwcheck_count	NUMBER;
	v_invsumm_id 			chain.card.card_id%TYPE;
	v_invsummwcheck_id		chain.card.card_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin;

	SELECT count(*)
	  INTO v_invsumm_count
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.InvitationSummary';

	SELECT count(*)
	  INTO v_invsummwcheck_count
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.InvitationSummaryWithCheck';

	IF v_invsumm_count > 0 AND v_invsummwcheck_count > 0 THEN
		SELECT card_id
		  INTO v_invsumm_id
		  FROM chain.card
		 WHERE js_class_type = 'Chain.Cards.InvitationSummary';

		SELECT card_id
		  INTO v_invsummwcheck_id
		  FROM chain.card
		 WHERE js_class_type = 'Chain.Cards.InvitationSummaryWithCheck';

		FOR rec IN (SELECT * 
					  FROM chain.card_group_card
					 WHERE card_id = v_invsummwcheck_id)
		LOOP
			INSERT INTO chain.card_group_card
			(app_sid, card_group_id, card_id, position, required_permission_set, invert_capability_check, required_capability_id, force_terminate)
			VALUES
			(rec.app_sid, rec.card_group_id, v_invsumm_id, rec.position, rec.required_permission_set, rec.invert_capability_check, rec.required_capability_id, rec.force_terminate);

			UPDATE chain.card_group_progression
			   SET from_card_id = v_invsumm_id
			 WHERE app_sid = rec.app_sid
			   AND card_group_id = rec.card_group_id
			   AND from_card_id = v_invsummwcheck_id;

			UPDATE chain.card_group_progression
			   SET to_card_id = v_invsumm_id
			 WHERE app_sid = rec.app_sid
			   AND card_group_id = rec.card_group_id
			   AND to_card_id = v_invsummwcheck_id;

			DELETE FROM chain.card_group_card
			 WHERE app_sid = rec.app_sid
			   AND card_group_id = rec.card_group_id
			   AND card_id = v_invsummwcheck_id;
		END LOOP;

		DELETE FROM chain.card_progression_action
		 WHERE card_id = v_invsummwcheck_id;

		DELETE FROM chain.card
		 WHERE card_id = v_invsummwcheck_id;
	END IF;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
