-- Please update version.sql too -- this keeps clean builds in sync
define version=43
@update_header

PROMPT set gt supplier sus relation type to nullable 

ALTER TABLE SUPPLIER.GT_SUPPLIER_ANSWERS
MODIFY(GT_SUS_RELATION_TYPE_ID  NULL);


@update_tail
