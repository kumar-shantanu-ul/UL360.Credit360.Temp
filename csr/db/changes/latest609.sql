-- Please update version.sql too -- this keeps clean builds in sync
define version=609
@update_header

update csr.dataview_ind_member set calculation_type_id = 0 where calculation_type_id is null;
ALTER TABLE csr.DATAVIEW_IND_MEMBER MODIFY CALCULATION_TYPE_ID DEFAULT 0 NOT NULL;
 
@update_tail
