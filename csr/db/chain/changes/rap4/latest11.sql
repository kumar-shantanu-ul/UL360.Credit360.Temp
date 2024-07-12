define rap4_version=11
@update_header


ALTER TABLE COMPONENT_TYPE ADD (
	EDIT_WIZARD_CLASS    VARCHAR2(255)
);

@..\..\component_pkg
@..\..\component_body

INSERT INTO card_group
(card_group_id, name, description, require_all_cards)
VALUES
(14, 'Logical Component Wizard', 'Used to build a single logical component', 0);

INSERT INTO card_group
(card_group_id, name, description, require_all_cards)
VALUES
(15, 'Purchased Component Wizard', 'Used to build a single logical component', 0);

@update_tail