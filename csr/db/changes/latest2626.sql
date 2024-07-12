-- Please update version.sql too -- this keeps clean builds in sync
define version=2626
@update_header

-- this was wrong in create_schema.sql. It appears to be ok on live, but may need fixing for other people
alter table csr.INITIATIVE_GROUP_FLOW_STATE DROP PRIMARY KEY DROP INDEX;
 
alter table csr.INITIATIVE_GROUP_FLOW_STATE ADD CONSTRAINT PK_INITIATIVE_GROUP_FLOW_STATE PRIMARY KEY (APP_SID, INITIATIVE_USER_GROUP_ID, FLOW_STATE_ID, PROJECT_SID);

@update_tail
