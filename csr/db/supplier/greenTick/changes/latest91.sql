-- Please update version.sql too -- this keeps clean builds in sync
define version=91
@update_header
	
UPDATE SUPPLIER.GT_TRANS_PACK_TYPE
SET    
       DESCRIPTION           = 'Bulk single trip outers for singles to store delivery'
WHERE  GT_TRANS_PACK_TYPE_ID = 1;

INSERT INTO SUPPLIER.GT_TRANS_PACK_TYPE (
   GT_TRANS_PACK_TYPE_ID, DESCRIPTION, POS, GT_SCORE) 
VALUES (7, 'Reusable transit trays / outers', 7, 0.5);


@update_tail