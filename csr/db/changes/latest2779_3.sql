-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_capability_id					NUMBER(10);
	v_card_group_id					NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;

	SELECT capability_id
	  INTO v_capability_id
	  FROM chain.capability
	 WHERE capability_type_id = 0
	   AND capability_name = 'Create company user without invitation';
	   
	UPDATE chain.card_group_card
	   SET required_capability_id = v_capability_id
	 WHERE card_group_id = (
		SELECT card_group_id
		  FROM chain.card_group
		 WHERE name = 'Company Invitation Wizard'
	 )
	   AND card_id IN (
		SELECT card_id
		  FROM chain.card
		 WHERE description IN (
			'Choose between creating new company or searching for and selecting existing company by company type',
			'Choose between adding new contacts or proceeding without adding any contacts',
			'Add new contacts',
			'Personalize invitation e-mail'
		 )
	 );
END;
/

-- ** New package grants **

-- *** Packages ***

@..\chain\setup_body

@update_tail
