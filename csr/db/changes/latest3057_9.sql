-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=9
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
	v_card_id	NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;

	DELETE FROM chain.card_group_card 
	 WHERE card_group_id = 52;/*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ActivityFilter';
	
	-- setup filter card for all sites with chain
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, v_card_id, 0);
	END LOOP;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ActivityFilterAdapter';

	 FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 52 /*chain.filter_pkg.FILTER_TYPE_ACTIVITIES*/, v_card_id, 1);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/setup_body

@update_tail
