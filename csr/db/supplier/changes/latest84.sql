-- Please update version.sql too -- this keeps clean builds in sync
define version=84
@update_header

connect aspen2/aspen2@&_CONNECT_IDENTIFIER
grant select, references, insert on aspen2.filecache to supplier;

connect supplier/supplier@&_CONNECT_IDENTIFIER

@update_tail
