-- Please update version.sql too -- this keeps clean builds in sync
define version=361
@update_header

/* possibly useful if you have local data that's messed up
update val set period_start_dtm = trunc(period_start_dtm,'MON'), period_end_dtm = trunc(period_end_dtm,'MON')
where (period_start_dtm != trunc(period_start_dtm,'MON') or period_end_dtm != trunc(period_end_dtm,'MON'));
update val_change set period_start_dtm = trunc(period_start_dtm,'MON'), period_end_dtm = trunc(period_end_dtm,'MON')
where (period_start_dtm != trunc(period_start_dtm,'MON') or period_end_dtm != trunc(period_end_dtm,'MON'));
update imp_val set start_dtm = trunc(start_dtm,'MON'), end_dtm = trunc(end_dtm,'MON')
where  (start_dtm != trunc(start_dtm,'MON') or end_dtm != trunc(end_dtm,'MON'));
*/

ALTER TABLE VAL DROP CONSTRAINT CK_VAL_START_DATE;
ALTER TABLE VAL DROP CONSTRAINT CK_VAL_END_DATE;

ALTER TABLE VAL ADD CONSTRAINT CK_VAL_DATES CHECK(PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM);
ALTER TABLE VAL_CHANGE ADD CONSTRAINT CK_VAL_CHANGE_DATES CHECK(PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM);
ALTER TABLE IMP_VAL ADD CONSTRAINT CK_IMP_VAL_DATES CHECK(START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);
ALTER TABLE SHEET ADD CONSTRAINT CK_SHEET_DATES CHECK(START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);
ALTER TABLE DELEGATION ADD CONSTRAINT CK_DELEGATION_DATES CHECK(START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

@update_tail
