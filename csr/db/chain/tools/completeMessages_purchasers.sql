/* Bugfix related to FB32580 
Issue: Messages have not been marked as completed when a qnnairer is accepted, resulting into being still displayed in the buyer's
'items requiring your attention' dashboard
*/
spool on;
SET wrap off;
SET linesize 9999;
spool incompleteMessage_buyer.log;

PROMPT >> Please enter a host:
exec security.user_pkg.logonadmin('&1');

DECLARE v_original_sid security_pkg.T_SID_ID := security_pkg.GetSID;
		v_exec_date DATE :=	sysdate;
BEGIN
	delete from chain.xx_FB32580 
	 where app_sid = sys_context('security', 'app')
	   and share_status_id = chain.chain_pkg.SHARED_DATA_ACCEPTED
	   and primary_lookup_id = chain.chain_pkg.QUESTIONNAIRE_SUBMITTED
	   and secondary_lookup_id = chain.chain_pkg.PURCHASER_MSG;
	
	dbms_output.put_line('Time of exec: ' || v_exec_date || ' client app sid: ' ||  sys_context('security', 'app'));

	FOR r IN (
		select md.message_template, r.to_company_sid, m.re_company_sid, q.questionnaire_id, qsle.entry_dtm, qt.questionnaire_type_id, mdl.primary_lookup_id, mdl.secondary_lookup_id, m.message_id, md.completion_type_id, m.created_dtm, 
			qsle.share_status_id, qsle.user_sid
			from chain.v$message m
			join chain.v$message_definition md  on (m.message_definition_id = md.message_definition_id)
			join chain.message_definition_lookup mdl on (md.message_definition_id = mdl.message_definition_id)
			join chain.message_recipient mr on (m.message_id = mr.message_id)
			join chain.recipient r on (mr.recipient_id = r.recipient_id)
			join chain.questionnaire_type qt on (m.re_questionnaire_type_id = qt.questionnaire_type_id)
			join chain.questionnaire q on (qt.questionnaire_type_id = q.questionnaire_type_id)
			join chain.questionnaire_share qs on (q.questionnaire_id = qs.questionnaire_id)
			join chain.qnr_share_log_entry qsle on (qs.questionnaire_share_id = qsle.questionnaire_share_id) 
		   where md.completion_type_id <> 0
			 and m.completed_dtm is null
			 and m.re_questionnaire_type_id is not null    
			 and mdl.primary_lookup_id = chain.chain_pkg.QUESTIONNAIRE_SUBMITTED 
			 and mdl.secondary_lookup_id = chain.chain_pkg.PURCHASER_MSG 
			 and m.re_company_sid = qs.qnr_owner_company_sid
			 and qsle.entry_dtm > date '2013-01-01'
			 and qsle.share_status_id = chain.chain_pkg.SHARED_DATA_ACCEPTED 
			 and r.to_company_sid = qs.share_with_company_sid
			 and (qsle.questionnaire_share_id,  qsle.share_log_entry_index) in (
				  select questionnaire_share_id, min(share_log_entry_index)
					from chain.qnr_share_log_entry
				   where app_sid = sys_context('security', 'app')					
					 and share_status_id =  qsle.share_status_id
				   group by questionnaire_share_id
			)
			order by qsle.entry_dtm
	)
	LOOP
		--insert into temp_table xx_FB32580
		insert into chain.xx_FB32580 (message_id, to_company_sid, re_company_sid, questionnaire_id, questionnaire_type_id, entry_dtm, share_status_id, user_sid, primary_lookup_id, secondary_lookup_id)
			values( r.message_id, r.to_company_sid,  r.re_company_sid,  r.questionnaire_id, r.questionnaire_type_id, r.entry_dtm, r.share_status_id, r.user_sid, r.primary_lookup_id, r.secondary_lookup_id);
		
		
		dbms_output.put_line('msg_id: ' || r.message_id || ' questionnaire_id: ' ||  r.questionnaire_id || ' questionnaire_type_id: ' 
			||  r.questionnaire_type_id || '	to_company_sid: ' || r.to_company_sid || '	re_company_sid: ' || r.re_company_sid 
			|| '	entry_dtm: ' || r.entry_dtm || '	user_sid: ' || r.user_sid);
		
		--set sid_context to user_sid
		security_pkg.setContext('SID', r.user_sid);
		
		dbms_output.put_line('Context set to sid: ' || security_pkg.getSid);
		
		update chain.message
			set completed_dtm = r.entry_dtm,
			completed_by_user_sid = sys_context('security', 'sid')
		  where app_sid = sys_context('security', 'app')
			and message_id = r.message_id
			and message_definition_id in (
				select message_definition_id
				from chain.v$message_definition
				where completion_type_id <> chain.chain_pkg.no_completion
				);	
			
		--revert context 
		security_pkg.setContext('SID', v_original_sid);
		
	END LOOP;

END;
/

commit;

spool off;