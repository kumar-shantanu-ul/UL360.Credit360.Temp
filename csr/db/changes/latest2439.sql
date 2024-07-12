-- Please update version.sql too -- this keeps clean builds in sync
define version=2439
@update_header

INSERT INTO csr.capability (NAME,ALLOW_BY_DEFAULT) VALUES ('Search all sections', 1);

@../section_search_body

@update_tail
