-- Please update version.sql too -- this keeps clean builds in sync
define version=1217
@update_header

alter table CT.PS_ITEM drop CONSTRAINT TUC_PS_ITEM_UNIQUE_ROW;
alter table CT.PS_ITEM add CONSTRAINT TUC_PS_ITEM_UNIQUE_ROW UNIQUE (WORKSHEET_ID, ROW_NUMBER);

@update_tail
