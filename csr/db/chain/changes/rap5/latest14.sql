define rap5_version=14
@update_header

DECLARE
	v_cg_id  		card_group.card_group_id%TYPE;
BEGIN

	user_pkg.logonadmin;
	
	v_cg_id := card_pkg.GetCardGroupId('Temporary Invitation Wizard');
	DELETE FROM card_group_progression WHERE card_group_id = v_cg_id;
	DELETE FROM card_group_card WHERE card_group_id = v_cg_id;
	DELETE FROM card_group WHERE card_group_id = v_cg_id;
	
	v_cg_id := card_pkg.GetCardGroupId('Simple Questionnaire Invitation');
	DELETE FROM card_group_progression WHERE card_group_id = v_cg_id;
	DELETE FROM card_group_card WHERE card_group_id = v_cg_id;
	DELETE FROM card_group WHERE card_group_id = v_cg_id;
END;
/

@update_tail