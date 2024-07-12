-- Please update version too -- this keeps clean builds in sync
define version=1753
@update_header

grant select on csr.v$region to chem;

@update_tail
