-- Please update version.sql too -- this keeps clean builds in sync
define version=32
@update_header

-- ISSUE 38 - scoring
UPDATE SUPPLIER.GT_PDA_PROVENANCE_TYPE
SET    SCORE                     = 1
WHERE  GT_PDA_PROVENANCE_TYPE_ID = 8; -- mineral



		
@update_tail