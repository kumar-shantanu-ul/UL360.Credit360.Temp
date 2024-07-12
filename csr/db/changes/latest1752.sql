-- Please update version too -- this keeps clean builds in sync
define version=1752
@update_header


-- recompiles added For andrei

@..\chain\product_pkg
@..\chain\product_body

@update_tail
