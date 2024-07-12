-- Please update version.sql too -- this keeps clean builds in sync
define version=2501
@update_header

grant select,insert on csr.rss_cache to csrimp;

@../schema_body
@../../../aspen2/cms/db/tab_body

@update_tail
