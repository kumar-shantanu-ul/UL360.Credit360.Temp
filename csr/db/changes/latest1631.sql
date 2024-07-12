-- Please update version.sql too -- this keeps clean builds in sync
define version=1631
@update_header

grant select, references on chain.saved_filter to csr;

Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1034,'Issue Chart','Credit360.Portlets.IssueChart', EMPTY_CLOB(),'/csr/site/portal/portlets/IssueChart.js');

@..\issue_pkg
@..\chain\filter_pkg
@..\issue_body
@..\chain\filter_body

@update_tail
