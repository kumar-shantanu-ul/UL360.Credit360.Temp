-- Please update version.sql too -- this keeps clean builds in sync
define version=1316
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

grant insert on csr.alert_frame to csrimp;
grant insert on csr.alert_frame_body to csrimp;
grant insert on csr.alert_template to csrimp;
grant insert on csr.alert_template_body to csrimp;

@../csrimp/imp_pkg
@../csrimp/imp_body
@../schema_pkg
@../schema_body
@../../../aspen2/cms/db/tab_body

@update_tail
