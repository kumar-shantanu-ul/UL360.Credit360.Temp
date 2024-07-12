-- Please update version.sql too -- this keeps clean builds in sync
define version=426
@update_header

connect aspen2/aspen2@&_CONNECT_IDENTIFIER

grant insert, update, delete on aspen2.filecache to web_user;

connect csr/csr@&_CONNECT_IDENTIFIER

@update_tail
