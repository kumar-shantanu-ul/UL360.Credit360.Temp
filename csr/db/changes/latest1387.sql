-- Please update version.sql too -- this keeps clean builds in sync
define version=1387
@update_header

--ALTER TABLE CHEM.SUBSTANCE_USE ADD CONSTRAINT UK_SUBSTANCE_USE UNIQUE (SUBSTANCE_ID, PROCESS_DESTINATION_ID, REGION_SID, ROOT_DELEGATION_SID, START_DTM, END_DTM, APP_SID);

@update_tail