-- Please update version.sql too -- this keeps clean builds in sync
define version=1623
@update_header

CREATE OR REPLACE VIEW donations.v$funding_commitment AS
	SELECT app_sid, funding_commitment_sid, scheme_sid, recipient_sid, region_group_sid, region_sid, donation_status_sid, csr_user_sid, charity_budget_tag_id, name, description, payment_dtm, reminder_dtm, notes, review_on_expiry, last_review_dtm, reminder_sent_dtm,
		  CASE 
			WHEN budget_end_dtm IS NULL THEN 10 /* FC_NO_BUDGETS */ 
			WHEN budget_end_dtm > SYSDATE THEN 1 /* FC_ACTIVE */ 
			WHEN review_on_expiry = 1 THEN 3 /* FC_EXPIRED_PENDING_REV*/ 
			ELSE 2 /* FC_EXPIRED */ END status
	FROM
	(
		SELECT fc.app_sid, fc.funding_commitment_sid, fc.scheme_sid, fc.recipient_sid, fc.region_group_sid, fc.region_sid, fc.donation_status_sid, fc.csr_user_sid, fc.charity_budget_tag_id, fc.name, fc.description, fc.payment_dtm, fc.reminder_dtm, fc.notes, fc.review_on_expiry, fc.last_review_dtm, fc.reminder_sent_dtm,
		(
			SELECT MAX(b.end_dtm)
			  FROM donations.budget b
			    JOIN donations.fc_budget fb ON fb.budget_id = b.budget_id AND fb.app_sid = b.app_sid
			    JOIN donations.donation d ON b.budget_id = d.budget_id AND d.app_sid = b.app_sid
			    JOIN donations.fc_donation fd ON fd.donation_id = d.donation_id and b.budget_id = d.budget_id AND fd.funding_commitment_sid = fb.funding_commitment_sid
			 WHERE fb.funding_commitment_sid = fc.funding_commitment_sid AND fb.app_sid = fc.app_sid
		) budget_end_dtm
		FROM donations.funding_commitment fc
	);
							 
@update_tail
