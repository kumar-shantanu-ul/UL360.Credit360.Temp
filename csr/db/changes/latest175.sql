-- Please update version.sql too -- this keeps clean builds in sync
define version=175
@update_header

INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (13, 0, 0, 'Form');
		 
@update_tail
