define version=12
@update_header

INSERT INTO card_group
(card_group_id, name, description, require_all_cards)
VALUES
(9, 'Simple Questionnaire Invitation', 'Allows inviting new or existing suppliers to complete a questionnaire. The cards in the wizard are expected to provide the invitation data.', 1);

INSERT INTO card_group
(card_group_id, name, description, require_all_cards)
VALUES
(10, 'Temporary Invitation Wizard', 'A wizard implementation for inviting new or existing suppliers to complete a questionnaire using a wizard onboarding.', 1);

ALTER TABLE chain.CARD ADD (
    CONFIG           CLOB,
    UNIQUE_NAME      VARCHAR2(1000)
);



@update_tail
