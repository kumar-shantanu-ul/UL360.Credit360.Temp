-- Please update version too -- this keeps clean builds in sync
define version=1850
@update_header

--ALTER TABLE csrimp.export_feed DROP COLUMN username;

grant insert on csr.export_feed to csrimp;
grant insert on csr.export_feed_cms_form to csrimp;
grant insert on csr.export_feed_dataview to csrimp;
grant insert on csr.export_feed_stored_proc to csrimp;

@..\imp_pkg
@..\imp_body

@update_tail
