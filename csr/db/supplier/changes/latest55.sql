-- Please update version.sql too -- this keeps clean builds in sync
define version=55
@update_header

PROMPT add processed palm oil column
ALTER TABLE SUPPLIER.GT_FORMULATION_ANSWERS
ADD (BP_PALM_PROCESSED_PCT NUMBER(6,3));

-- just easier to set value than have incomplete models

update GT_FORMULATION_ANSWERS set BP_PALM_PROCESSED_PCT = 0; 

@update_tail
