-- Please update version.sql too -- this keeps clean builds in sync
define version=1778
@update_header

-- update measures created by quick_survey_pkg to be indivisible
update csr.measure 
  set divisibility = 2
where divisibility = 1 and
		name in ('score_threshold', 'quick_survey_score_pct', 'quick_survey_score', 'quick_survey_number') and
		(app_sid, measure_sid) in (
		select aigm.app_sid, i.measure_sid
		  from csr.aggregate_ind_group_member aigm, csr.quick_survey qs, csr.ind i
		 where qs.app_sid = aigm.app_sid and qs.aggregate_ind_group_id = aigm.aggregate_ind_group_id
		   and i.app_sid = aigm.app_sid and i.ind_sid = aigm.ind_sid);

-- recalc all survey-based aggregate inds
insert into csr.val_change_log (app_sid, ind_sid, start_dtm, end_dtm)
	select distinct aigm.app_sid, i.ind_sid, date '1990-01-01', date '2021-01-01'
	  from csr.aggregate_ind_group_member aigm, csr.quick_survey qs, csr.ind i
	 where qs.app_sid = aigm.app_sid and qs.aggregate_ind_group_id = aigm.aggregate_ind_group_id
	   and i.app_sid = aigm.app_sid and i.ind_sid = aigm.ind_sid;


@update_tail