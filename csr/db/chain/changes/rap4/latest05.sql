define rap4_version=5
@update_header

INSERT INTO card_group
(card_group_id, name, description, require_all_cards)
VALUES
(13, 'Wood Source Wizard', 'Used by Rainforest Alliance to capture accreditation details for wood', 0);

@update_tail
