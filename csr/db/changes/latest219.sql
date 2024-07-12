-- Please update version.sql too -- this keeps clean builds in sync
define version=219
@update_header

CREATE INDEX IX_PENDING_REGION_PARENT ON PENDING_REGION(PARENT_REGION_ID)
TABLESPACE INDX;

@update_tail