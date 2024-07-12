-- Please update version.sql too -- this keeps clean builds in sync
define version=1120
@update_header

ALTER TABLE CT.BT_PROFILE DROP CONSTRAINT B_R_BT_PRF;
ALTER TABLE CT.BT_PROFILE DROP CONSTRAINT PK_BT_PRF;

ALTER TABLE CT.BT_PROFILE DROP COLUMN BREAKDOWN_ID;
ALTER TABLE CT.BT_PROFILE DROP COLUMN REGION_ID;

ALTER TABLE CT.BT_PROFILE ADD BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL;

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT PK_BT_PRF PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID);

ALTER TABLE CT.BT_PROFILE ADD CONSTRAINT BD_GROUP_BT_PRF 
     FOREIGN KEY (APP_SID, COMPANY_SID, BREAKDOWN_GROUP_ID) REFERENCES CT.BREAKDOWN_GROUP (APP_SID,COMPANY_SID,BREAKDOWN_GROUP_ID);*/


INSERT INTO CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID, DESCRIPTION) VALUES (1, 'Money');	
INSERT INTO CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID, DESCRIPTION) VALUES (2, 'Distance');
INSERT INTO CT.BT_ESTIMATE_TYPE (BT_ESTIMATE_TYPE_ID, DESCRIPTION) VALUES (3, 'Time');

create or replace package ct.breakdown_group_pkg as
procedure dummy;
end;
/
create or replace package body ct.breakdown_group_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on ct.breakdown_group_pkg to web_user;

--Create temporary packages needed to drop capability - just relevant snapshotted parts have been put there
@@latest1120_packages

BEGIN
	-- logon as builtin admin, no app
	security.user_pkg.logonadmin;
	chain.temp_capability_pkg.DeleteCapability(1, 'CT Employee Commute');
	chain.temp_capability_pkg.DeleteCapability(2, 'CT Employee Commute');
END;
/

DROP PACKAGE chain.temp_capability_pkg;

@..\ct\ct_pkg
@..\ct\breakdown_group_pkg	
@..\ct\breakdown_group_body
@..\ct\emp_commute_pkg
@..\ct\emp_commute_body

@update_tail