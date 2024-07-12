-- Please update version.sql too -- this keeps clean builds in sync
define version=78
@update_header

ALTER TABLE gt_packaging_answers
ADD CONSTRAINT settle_in_transit_chk
   CHECK (settle_in_transit IN (-1, 1,2,3));

@update_tail