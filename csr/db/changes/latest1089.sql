-- Please update version.sql too -- this keeps clean builds in sync
define version=1089
@update_header

-- fix latest1082.sql incorrect constraints
ALTER TABLE DONATIONS.REGION_FILTER_TAG_GROUP DROP CONSTRAINT PK141;
ALTER TABLE DONATIONS.REGION_FILTER_TAG_GROUP ADD CONSTRAINT  PK141 PRIMARY KEY (APP_SID, REGION_TAG_GROUP_ID);

@update_tail
