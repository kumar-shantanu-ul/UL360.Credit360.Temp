define version=975
@update_header

alter table CSR.QUICK_SURVEY_ANSWER add ANSWER_CLOB CLOB;
update CSR.QUICK_SURVEY_ANSWER set ANSWER_CLOB = ANSWER;
alter table CSR.QUICK_SURVEY_ANSWER drop column ANSWER;
alter table CSR.QUICK_SURVEY_ANSWER rename column ANSWER_CLOB to ANSWER;

@@..\quick_survey_body

@update_tail

