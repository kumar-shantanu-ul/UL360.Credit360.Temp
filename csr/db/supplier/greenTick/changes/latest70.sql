-- Please update version.sql too -- this keeps clean builds in sync
define version=70
@update_header

ALTER TABLE gt_pdesign_answers MODIFY(materials_note  NULL);

@update_tail