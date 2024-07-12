-- Please update version.sql too -- this keeps clean builds in sync
define version=17
@update_header

-- run on live by RK on 6/4/06

alter table ind_window add (comparison_offset number(10) default -1);

begin
INSERT INTO SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION ) VALUES (10, 'Entered with modifications'); 
INSERT INTO SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (10, 1, 0, 0, 0, 0, 0, 1);
INSERT INTO SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (10, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (10, 3, 0, 0, 0, 0, 0, 0);
end;
/
commit;

@update_tail
