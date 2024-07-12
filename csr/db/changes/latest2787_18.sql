-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.QUICK_SURVEY_ANSWER ADD (
	LOG_ITEM CLOB
);
ALTER TABLE CSR.QS_ANSWER_LOG ADD (
	LOG_ITEM CLOB
);
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN DESCRIPTION TO XXX_DESCRIPTION;
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN PARAM_1 TO XXX_PARAM_1;
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN PARAM_2 TO XXX_PARAM_2;
ALTER TABLE CSR.QS_ANSWER_LOG RENAME COLUMN PARAM_3 TO XXX_PARAM_3;
ALTER TABLE CSR.QS_ANSWER_LOG MODIFY XXX_DESCRIPTION VARCHAR2(255) NULL;

ALTER TABLE CSRIMP.QS_ANSWER_LOG ADD (
	LOG_ITEM CLOB
);
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN DESCRIPTION;
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN PARAM_1;
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN PARAM_2;
ALTER TABLE CSRIMP.QS_ANSWER_LOG DROP COLUMN PARAM_3;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	--deal with most questions
	update csr.qs_answer_log
	set log_item = xxx_param_3
	where (app_sid, survey_response_id, question_id) in (
		select qsq.app_sid, qsa.survey_response_id, qsq.question_id
		from CSR.quick_survey_question qsq
		join csr.quick_survey_answer qsa on qsq.app_sid = qsa.app_sid and qsq.question_id = qsa.question_id
		where qsq.question_type in ('note','rtquestion','richtext','custom','number','slider')
	)
	and xxx_param_3 is not null;

	--deal with dates
	update csr.qs_answer_log
	set log_item =  to_date('18991230','yyyyMMdd') + cast(xxx_param_3 as number)
	where (app_sid, survey_response_id, question_id) in (
		select qsq.app_sid, qsa.survey_response_id, qsq.question_id
		from CSR.quick_survey_question qsq
		join csr.quick_survey_answer qsa on qsq.app_sid = qsa.app_sid and qsq.question_id = qsa.question_id
		where qsq.question_type in ('date')
	)
	and xxx_param_3 is not null;

	--partly deal with radio buttons
	update csr.qs_answer_log
	set log_item = 'Other: ' || xxx_param_3
	where (app_sid, survey_response_id, question_id) in (
		select qsq.app_sid, qsa.survey_response_id, qsq.question_id
		from CSR.quick_survey_question qsq
		join csr.quick_survey_answer qsa on qsq.app_sid = qsa.app_sid and qsq.question_id = qsa.question_id
		where qsq.question_type in ('radio')
	)
	and xxx_param_3 is not null;
	
	--partly deal with matrixes
	--matrixes step 1: insert missing answers
	--might be long-running
	insert into csr.quick_survey_answer (app_sid, survey_response_id, question_id, log_item, version_stamp, submission_id, survey_version)
	select c.app_sid, c.survey_response_id, c.checkboxgroup_question_id, c.new_param_3, c.version_stamp, c.submission_id, c.survey_version
	from (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id, 
			'?' new_param_3, -1 version_stamp, submission_id, qsr.survey_version
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('radiorow') --to merge into matrix
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, submission_id, qsr.survey_version
	) c
	left join csr.quick_survey_answer a
		 on a.app_sid = c.app_sid
		and a.survey_response_id = c.survey_response_id
		and a.question_id = c.checkboxgroup_question_id
		and a.submission_id = c.submission_id
		and a.survey_version = c.survey_version
	where a.app_sid is null;

	--matrixes step 2: upsert qs_answer_log from child questions
	--might be long-running
	merge into csr.qs_answer_log a
	using (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id,
			trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60) new_set_date,
			'?' new_param_3,
			submission_id, set_by_user_sid
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('radiorow') --to merge into matrix
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60), submission_id, set_by_user_sid
	) c on (a.app_sid = c.app_sid
	   and a.survey_response_id = c.survey_response_id
	   and a.question_id = c.checkboxgroup_question_id
	   and trunc(a.set_dtm, 'MI') + trunc(to_char(a.set_dtm, 'ss')/4)*4/(24 * 60 * 60) = c.new_set_date)
	when matched then
		update
		   set a.log_item = c.new_param_3
	when not matched then
		insert (a.app_sid, a.qs_answer_log_id, a.survey_response_id, a.question_id, a.version_stamp, a.submission_id, a.set_by_user_sid, a.set_dtm, a.log_item)
		values (c.app_sid, csr.qs_answer_log_id_seq.NEXTVAL, c.survey_response_id, c.checkboxgroup_question_id, 0, c.submission_id, c.set_by_user_sid, c.new_set_date, c.new_param_3)
	;

	--deal with checkboxes
	--checkboxes part 1: insert missing answers
	--might be long-running
	insert into csr.quick_survey_answer (app_sid, survey_response_id, question_id, log_item, version_stamp, submission_id, survey_version)
	select c.app_sid, c.survey_response_id, c.checkboxgroup_question_id, c.new_param_3, c.version_stamp, c.submission_id, c.survey_version
	from (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id, 
			replace(csr.stragg2(
				case
					when xxx_param_3 is null or xxx_param_3 = '0' then ''
					when xxx_param_3 = '1' then qsq.label || chr(10)
					else qsq.label || ': ' || xxx_param_3 || chr(10)
				end
			),chr(10)||',',chr(10)) new_param_3,
			-1 version_stamp, submission_id, qsr.survey_version
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('checkbox') --to merge into checkboxgroup
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, submission_id, qsr.survey_version
	) c
	left join csr.quick_survey_answer a
		 on a.app_sid = c.app_sid
		and a.survey_response_id = c.survey_response_id
		and a.question_id = c.checkboxgroup_question_id
		and a.submission_id = c.submission_id
		and a.survey_version = c.survey_version
	where a.app_sid is null;

	--might be long-running
	--checkboxes part 2: upsert qs_answer_log
	merge into csr.qs_answer_log a
	using (
		select qal.app_sid, qal.survey_response_id, qsq.parent_id checkboxgroup_question_id,
			trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60) new_set_date,
			replace(csr.stragg2(
				case
					when xxx_param_3 is null or xxx_param_3 = '0' then ''
					when xxx_param_3 = '1' then qsq.label || chr(10)
					else qsq.label || ': ' || xxx_param_3 || chr(10)
				end
			),chr(10)||',',chr(10)) new_param_3,
			submission_id, set_by_user_sid
		from csr.qs_answer_log qal
		join csr.quick_survey_question qsq on qal.app_sid = qsq.app_sid and qal.question_id = qsq.question_id
		join csr.quick_survey_response qsr on qsq.app_sid = qsr.app_sid and qsq.survey_sid = qsr.survey_sid and qal.survey_response_id = qsr.survey_response_id and qsq.survey_version = qsr.survey_version
		where qsq.question_type in ('checkbox') --to merge into checkboxgroup
		group by qal.app_sid, qal.survey_response_id, qsq.parent_id, trunc(qal.set_dtm, 'MI') + trunc(to_char(qal.set_dtm, 'ss')/4)*4/(24 * 60 * 60), submission_id, set_by_user_sid
	) c on (a.app_sid = c.app_sid
	   and a.survey_response_id = c.survey_response_id
	   and a.question_id = c.checkboxgroup_question_id
	   and trunc(a.set_dtm, 'MI') + trunc(to_char(a.set_dtm, 'ss')/4)*4/(24 * 60 * 60) = c.new_set_date)
	when matched then
		update
		   set a.log_item = c.new_param_3
	when not matched then
		insert (a.app_sid, a.qs_answer_log_id, a.survey_response_id, a.question_id, a.version_stamp, a.submission_id, a.set_by_user_sid, a.set_dtm, a.log_item)
		values (c.app_sid, csr.qs_answer_log_id_seq.NEXTVAL, c.survey_response_id, c.checkboxgroup_question_id, 0, c.submission_id, c.set_by_user_sid, c.new_set_date, c.new_param_3)
	;
END;
/
-- ** New package grants **

-- *** Packages ***
@../quick_survey_pkg

@../quick_survey_body
@../csrimp/imp_body
@../schema_body

@update_tail
