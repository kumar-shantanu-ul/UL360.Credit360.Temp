-- Please update version.sql too -- this keeps clean builds in sync
define version=57
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER

GRANT UPDATE ON csr.file_upload TO donations;

connect donations/donations@&_CONNECT_IDENTIFIER

@../donation_pkg
@../donation_body

@update_tail
