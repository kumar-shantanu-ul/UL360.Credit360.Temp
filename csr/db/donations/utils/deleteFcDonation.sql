/* We don't want users being able to delete FC created donations */
PROMPT Enter host name 
PROMPT Enter donation_id

DECLARE 
	v_donation_id	number(10);
	v_cnt			number(10);
BEGIN
	user_pkg.logonadmin('&&1');
	v_donation_id := &&2;
  
	SELECT count(*) INTO v_cnt from fc_donation where donation_id = v_donation_id;
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Such donation doesn''t belong to Funding Commitment!');
	END IF;

	DELETE FROM fc_budget WHERE budget_id IN (
		SELECT budget_id FROM donation WHERE donation_id = v_donation_id
	);
	
	DELETE FROM fc_donation WHERE donation_id = v_donation_id;
	donation_pkg.deletedonation(sys_context('security','act'), v_donation_id);
END;
/