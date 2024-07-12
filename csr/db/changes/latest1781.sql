-- Please update version.sql too -- this keeps clean builds in sync
define version=1781
@update_header

GRANT DELETE ON DONATIONS.REGION_FILTER_TAG_GROUP TO CSR;

@..\tag_body

@update_tail