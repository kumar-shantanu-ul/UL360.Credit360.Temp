-- Please update version.sql too -- this keeps clean builds in sync
define version=2562
@update_header

UPDATE csr.module
   SET enable_sp='EnableFrameworks'
 WHERE enable_sp='EnableIndexes';

@..\enable_pkg
@..\enable_body

@update_tail