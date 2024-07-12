-- Please update version.sql too -- this keeps clean builds in sync
define version=173
@update_header
		 
begin
INSERT INTO PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (12, 0, 0, 'Date');
end;
/	
		 
@update_tail
