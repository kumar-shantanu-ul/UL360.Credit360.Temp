-- Please update version.sql too -- this keeps clean builds in sync
define version=319
@update_header

UPDATE val
   SET entry_val_number = val_number
 WHERE entry_measure_conversion_id IS NULL AND val_number IS NOT NULL AND entry_val_number IS NULL;

ALTER TABLE val ADD CONSTRAINT ck_val_num CHECK ( (val_number IS NOT NULL AND entry_val_number IS NOT NULL) OR (val_number IS NULL AND entry_val_number IS NULL) );

@update_tail