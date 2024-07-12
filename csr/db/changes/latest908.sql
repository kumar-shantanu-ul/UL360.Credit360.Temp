-- Please update version.sql too -- this keeps clean builds in sync
define version=908
@update_header

-- the name is really confusing -- i.e. it's nothing to do with filters -- it's stating
-- that the entry is visible or hidden (for new rows).
ALTER TABLE CMS.TAB_COLUMN RENAME COLUMN ENUMERATED_FILTER_FIELD TO ENUMERATED_HIDDEN_FIELD;

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body

ALTER TABLE csr.target_dashboard ADD 
	CONSTRAINT CHK_TGT_DASH_USE_ROOT_REG CHECK (USE_ROOT_REGION_SID IN (0,1));


@update_tail
