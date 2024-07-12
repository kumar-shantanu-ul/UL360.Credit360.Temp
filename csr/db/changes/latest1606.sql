-- Please update version.sql too -- this keeps clean builds in sync
define version=1606
@update_header

UPDATE csr.tpl_region_type
   SET label = 'Selected regions at bottom of tree'
 WHERE tpl_region_type_id = 13;

UPDATE csr.tpl_region_type
   SET label = 'Selected regions one level from bottom'
 WHERE tpl_region_type_id = 14;

@update_tail
