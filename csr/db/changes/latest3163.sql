-- Please update version.sql too -- this keeps clean builds in sync
define version=3163
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
DECLARE
	v_old_card_id	NUMBER;
	v_new_card_id	NUMBER;
BEGIN
	security.user_pkg.logonadmin;

	SELECT card_id
	  INTO v_old_card_id
	  FROM chain.card
	 WHERE lower(js_class_type) = lower('NPSL.Cms.Filters.CmsFilterAdapter');

	SELECT card_id
	  INTO v_new_card_id
	  FROM chain.card
	 WHERE lower(js_class_type) = lower('Credit360.Users.Filters.UserCmsFilterAdapter');

	UPDATE chain.card_group_card
	   SET card_id = v_new_card_id
	 WHERE card_group_id = 47 -- 'User Data Filter'
	   AND card_id = v_old_card_id
	   AND position = 1;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
