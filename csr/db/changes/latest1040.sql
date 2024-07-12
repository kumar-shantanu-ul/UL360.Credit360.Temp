-- Please update version.sql too -- this keeps clean builds in sync
define version=1040
@update_header

update csr.portlet set script_path = '/csr/site/portal/portlets/ct/hotspot.jsi'
where lower(script_path) like '/csr/site/portal/portlets/ct/%';

@update_tail
