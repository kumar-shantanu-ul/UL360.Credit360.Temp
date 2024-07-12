
-- Please update version.sql too -- this keeps clean builds in sync
define version=60
@update_header

ALTER TABLE SUPPLIER.GT_PDA_ACCRED_TYPE
ADD (NEEDS_NOTE NUMBER(1) DEFAULT 0 NOT NULL);

ALTER TABLE SUPPLIER.GT_PDA_MATERIAL_ITEM
ADD (ACCREDITATION_NOTE VARCHAR2(256 BYTE));

UPDATE SUPPLIER.GT_PDA_ACCRED_TYPE
SET    NEEDS_NOTE            = 1
WHERE  GT_PDA_ACCRED_TYPE_ID <=2 ;




@update_tail