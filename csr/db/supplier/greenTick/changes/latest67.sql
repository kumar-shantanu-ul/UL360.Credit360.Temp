-- Please update version.sql too -- this keeps clean builds in sync
define version=67
@update_header

-- sub product no assignment was wrong
delete from tag_tag_attribute where tag_attribute_id = 0;

-- free text field missed 

ALTER TABLE SUPPLIER.GT_PDESIGN_ANSWERS
ADD (MATERIALS_NOTE CLOB);

UPDATE SUPPLIER.GT_PDESIGN_ANSWERS SET MATERIALS_NOTE = 'Not set';

ALTER TABLE SUPPLIER.GT_PDESIGN_ANSWERS
MODIFY(MATERIALS_NOTE  NOT NULL);



@update_tail