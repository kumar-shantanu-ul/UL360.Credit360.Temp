-- Please update version.sql too -- this keeps clean builds in sync
define version=62
@update_header

UPDATE questionnaire SET description = friendly_name WHERE description IS NULL;

ALTER TABLE questionnaire MODIFY (
	DESCRIPTION  VARCHAR2(1024)  NOT NULL
);

@update_tail
