-- Please update version.sql too -- this keeps clean builds in sync
define version=1336
@update_header


begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_type='P' and table_name='QS_QUESTION_OPTION') loop
		execute immediate 'alter table csr.qs_question_option drop primary key cascade drop index';
	end loop;
	for r in (select 1 from all_constraints where owner='CSR' and constraint_type='U' and constraint_name='CONS_QUESTION_AND_OPTION') loop
		execute immediate 'alter table csr.qs_question_option drop constraint CONS_QUESTION_AND_OPTION cascade drop index';
	end loop;
end;
/
	
alter table csr.qs_question_option add 
    CONSTRAINT PK_QS_QUESTION_OPTION PRIMARY KEY (APP_SID, QUESTION_ID, QUESTION_OPTION_ID);
ALTER TABLE CSR.QS_FILTER_CONDITION ADD CONSTRAINT FK_QS_FIL_COND_CMP_OP 
    FOREIGN KEY (APP_SID, QUESTION_ID, COMPARE_TO_OPTION_ID)
    REFERENCES CSR.QS_QUESTION_OPTION(APP_SID, QUESTION_ID, QUESTION_OPTION_ID)
;
ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD CONSTRAINT FK_QS_Q_OPT_ANSWER 
    FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_OPTION_ID)
    REFERENCES CSR.QS_QUESTION_OPTION(APP_SID, QUESTION_ID, QUESTION_OPTION_ID)
;
alter table csrimp.qs_question_option drop primary key drop index;
alter table csrimp.qs_question_option drop constraint CONS_QUESTION_AND_OPTION drop index;
alter table csrimp.qs_question_option add
    CONSTRAINT PK_QS_QUESTION_OPTION PRIMARY KEY (QUESTION_ID, QUESTION_OPTION_ID);

@update_tail
