-- Please update version.sql too -- this keeps clean builds in sync
define version=179
@update_header

INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (14, 0, 0, 'FileUpload');
		 
@update_tail
