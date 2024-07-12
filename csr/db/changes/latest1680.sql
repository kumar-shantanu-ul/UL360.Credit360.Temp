-- Please update version.sql too -- this keeps clean builds in sync
define version=1680
@update_header

ALTER TABLE csr.feed ADD mapping_xml CLOB;

@../feed_body
@update_tail
