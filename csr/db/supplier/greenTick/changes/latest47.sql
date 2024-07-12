-- Please update version.sql too -- this keeps clean builds in sync
define version=47

@update_header

-- drop no palm and no endangered bit cols and add endangered pct as an explicit separate field - which I don't like but not my call
ALTER TABLE SUPPLIER.GT_PDESIGN_ANSWERS
 ADD (ENDANGERED_PCT  NUMBER(6,3));

ALTER TABLE SUPPLIER.GT_PDESIGN_ANSWERS DROP COLUMN NO_PALM_PRESENT;

ALTER TABLE SUPPLIER.GT_PDESIGN_ANSWERS DROP COLUMN NO_ENDANGERED_PRESENT;
	
@update_tail