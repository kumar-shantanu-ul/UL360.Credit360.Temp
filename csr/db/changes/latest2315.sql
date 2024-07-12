-- Please update version.sql too -- this keeps clean builds in sync
define version=2315
@update_header

ALTER TABLE CMS.TAB ADD (POLICY_VIEW VARCHAR(1024));

@../../../aspen2/cms/db/tab_body

@update_tail