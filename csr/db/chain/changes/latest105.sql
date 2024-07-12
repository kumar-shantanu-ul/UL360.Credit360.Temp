define version=105
@update_header

-- fixing up message definition 7 --> COMPLETE_QUESTIONNAIRE, SUPPLIER
CREATE TABLE chain.TMP_MESSAGE_FIX (
	APP_SID					NUMBER(10) NOT NULL,
	MESSAGE_ID				NUMBER(10) NOT NULL,
	QUESTIONNAIRE_TYPE_ID	NUMBER(10) NOT NULL,
	PURCHASER_COMPANY_SID	NUMBER(10) NOT NULL,
	SUPPLIER_COMPANY_SID	NUMBER(10) NOT NULL,
	PURCHASER_USER_SID		NUMBER(10) NOT NULL,
	SUPPLIER_USER_SID		NUMBER(10) NOT NULL
);

	INSERT INTO chain.tmp_message_fix
	(app_sid, message_id, questionnaire_type_id, purchaser_company_sid, supplier_company_sid, purchaser_user_sid, supplier_user_sid)
	SELECT r.app_sid, r.message_id, r.questionnaire_type_id, r.purchaser_company_sid, r.supplier_company_sid, i.from_user_sid purchaser_user_sid, i.to_user_sid
	  FROM supplier_relationship sr, invitation i, (
		SELECT m.app_sid, m.message_id, q.questionnaire_type_id, NVL(m.re_company_sid, co.top_company_sid) purchaser_company_sid, q.company_sid supplier_company_sid
		  FROM message m, action a, questionnaire q, customer_options co
		 WHERE m.app_sid = co.app_sid
		   AND m.app_sid = a.app_sid
		   AND m.app_sid = q.app_sid
		   AND m.action_id = a.action_id
		   AND a.related_questionnaire_id = q.questionnaire_id
		   AND m.re_questionnaire_type_id = q.questionnaire_type_id
		) r
	 WHERE r.app_sid = sr.app_sid
	   AND r.app_sid = i.app_sid
	   AND r.purchaser_company_sid = sr.purchaser_company_sid
	   AND r.supplier_company_sid = sr.supplier_company_sid
	   AND r.purchaser_company_sid = i.from_company_sid
	   AND r.supplier_company_sid = i.to_company_sid;
	
	-- fill in missing re_company_sid's
	UPDATE chain.message m
	   SET re_company_sid = (
	   		SELECT DISTINCT purchaser_company_sid
	   		  FROM tmp_message_fix f
	   		 WHERE m.message_id = f.message_id
	   )
	 WHERE message_id IN (SELECT message_id FROM tmp_message_fix)
	   AND re_company_sid IS NULL;
	
	-- make sure that our supplier followers are setup
	INSERT INTO chain.supplier_follower
	(app_sid, purchaser_company_sid, supplier_company_sid, user_sid)
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, purchaser_user_sid
	  FROM tmp_message_fix
	 MINUS
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, user_sid
	  FROM supplier_follower;
	
	-- make sure that our purchaser followers are setup
	INSERT INTO chain.purchaser_follower
	(app_sid, purchaser_company_sid, supplier_company_sid, user_sid)
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, supplier_user_sid
	  FROM tmp_message_fix
	 MINUS
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, user_sid
	  FROM purchaser_follower;
	  
	INSERT INTO chain.recipient
	(app_sid, recipient_id, to_company_sid, to_user_sid)
	SELECT app_sid, recipient_id_seq.nextval, supplier_company_sid, supplier_user_sid
	  FROM (
			SELECT app_sid, supplier_company_sid, supplier_user_sid
			  FROM tmp_message_fix
			 MINUS 
			SELECT app_sid, to_company_sid, to_user_sid
			  FROM recipient
		);

	INSERT INTO chain.message_recipient
	(app_sid, message_id, recipient_id)
	SELECT f.app_sid, f.message_id, r.recipient_id
	  FROM tmp_message_fix f, recipient r
	 WHERE f.app_sid = r.app_sid
	   AND f.supplier_company_sid = r.to_company_sid
	   AND f.supplier_user_sid = r.to_user_sid
	 MINUS 
	SELECT app_sid, message_id, recipient_id
	  FROM message_recipient;

DROP TABLE chain.TMP_MESSAGE_FIX;

@update_tail