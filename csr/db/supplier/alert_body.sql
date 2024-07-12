CREATE OR REPLACE PACKAGE BODY SUPPLIER.alert_pkg
IS

PROCEDURE GetAlertSchedules(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.app_sid, c.app_sid, b.run_time, b.day_of_week, b.day_of_month
		  FROM alert_batch b, csr.customer c
		 WHERE c.app_sid = b.app_sid;
END;


PROCEDURE GetUsersToRemind(
	in_app_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
        SELECT NULL FROM DUAL;
        -- commented out by RK to make it compile
        /*
		SELECT DISTINCT DECODE(
			p.product_status_id, 
				product_pkg.DATA_BEING_ENTERED, pqp.provider_sid,
				product_pkg.DATA_SUBMITTED, pq.approver_sid,
				product_pkg.DATA_BEING_REVIEWED, pqp.provider_sid) user_sid
		  FROM product p, product_questionnaire pq, product_questionnaire_provider pqp
		 WHERE p.product_id = pq.product_id
		 	 AND pq.product_id = pqp.product_id
		 	 AND pq.questionnaire_id = pqp.questionnaire_id
		   AND p.app_sid = in_app_sid
		   AND p.active = 1
		   AND p.product_status_id IN (
		 		product_pkg.DATA_BEING_ENTERED, 
		 		product_pkg.DATA_SUBMITTED, 
		 		product_pkg.DATA_BEING_REVIEWED
 			);
        */
END;

END alert_pkg;
/



