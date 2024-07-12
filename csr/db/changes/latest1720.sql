-- Please update version too -- this keeps clean builds in sync
define version=1720
@update_header

GRANT DELETE ON cms.tag TO csr;

@update_tail