-- Please update version.sql too -- this keeps clean builds in sync
define version=1954
@update_header

ALTER TABLE csr.teamroom_type ADD DEFAULT_NEW_USER_GROUP_SID NUMBER(10);

grant references on security.group_table to csr;

ALTER TABLE csr.teamroom_type ADD CONSTRAINT FK_TEAMROOM_TYPE_USER_GROUP 
	 FOREIGN KEY (DEFAULT_NEW_USER_GROUP_SID)
	 REFERENCES SECURITY.GROUP_TABLE(SID_ID);

@..\teamroom_pkg
@..\teamroom_body

@update_tail
