-- Please update version.sql too -- this keeps clean builds in sync
define version=557
@update_header

ALTER TABLE SHEET_ACTION ADD (
	DOWNSTREAM_DESCRIPTION	VARCHAR2(255)
);

UPDATE sheet_action SET downstream_description = description;

ALTER TABLE sheet_action MODIFY downstream_description NOT NULL;

UPDATE sheet_action SET downstream_description = 'Submitted - thank you' WHERE sheet_action_id = 1;

@@..\delegation_body

@update_tail
