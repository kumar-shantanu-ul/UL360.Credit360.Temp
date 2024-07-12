-- Please update version.sql too -- this keeps clean builds in sync
define version=144
@update_header


INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (11, 0, 0, 'Grid');

@update_tail
