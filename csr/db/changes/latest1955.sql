-- Please update version.sql too -- this keeps clean builds in sync
define version=1955
@update_header

DROP SEQUENCE CHAIN.CMS_ITEM_ID_SEQ;

GRANT EXECUTE ON CMS.CMS_TAB_PKG TO CHAIN;

@../../../aspen2/cms/db/cms_tab_pkg
@../chain/flow_form_pkg	

@../../../aspen2/cms/db/cms_tab_body
@../chain/flow_form_body	

@update_tail