-- Please update version.sql too -- this keeps clean builds in sync
define version=1799
@update_header

UPDATE chain.card
   SET js_include = '/csr/site/issues/IssuesFilter.jsi'
 WHERE js_include IN (
	'/csr/site/issues/standardIssuesFilter.js',
	'/csr/site/issues/issuesCustomFieldsFilter.js'
 );
 
 -- Workflow Alert changes.
ALTER TABLE csr.flow_transition_alert_cms_col
  ADD (ALERT_MANAGER_FLAG NUMBER(1) DEFAULT 0 NOT NULL);
  
ALTER TABLE csrimp.flow_transition_alert_cms_col
  ADD (ALERT_MANAGER_FLAG NUMBER(1) DEFAULT 0 NOT NULL);

@../schema_body;
@../csrimp/imp_body;
@../csr_user_pkg;
@../csr_user_body;
@../flow_pkg;
@../flow_body;
  
@update_tail
