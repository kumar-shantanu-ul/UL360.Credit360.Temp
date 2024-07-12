CREATE OR REPLACE PACKAGE BODY DONATIONS.sys_Pkg
IS

FUNCTION FormatPeriod(
    in_dtm      IN DATE, 
    in_base_dtm IN DATE, 
    in_interval IN CHAR
) RETURN VARCHAR2
AS
    v_interval CHAR(2);
    v_out VARCHAR2(255);
    v_base_start_month_num  NUMBER(2);
    v_rebased_month_num   NUMBER(2);
    v_rebased_dtm   DATE;
BEGIN
    -- rebase date donated as if year ran jan->jan (i.e. -2+1 = -1)
    v_base_start_month_num := TO_NUMBER(TO_CHAR(in_base_dtm,'MM'));
    -- TODO: fix this to truncate half-yearly (i.e. truncate to quarter then floor(x/2))
    v_rebased_dtm := TRUNC(  ADD_MONTHS(in_dtm, -v_base_start_month_num+1 ), in_interval);
    v_interval := UPPER(in_interval);
    v_rebased_month_num := TO_NUMBER(TO_CHAR(v_rebased_dtm,'MM'))-1;
    SELECT 
        CASE 
          WHEN v_interval = 'Y' AND v_base_start_month_num = 1 THEN TO_CHAR(v_rebased_dtm, 'YYYY')
          WHEN v_interval = 'Y' AND v_base_start_month_num != 1 THEN TO_CHAR(v_rebased_dtm, 'YY')||'/'||TO_CHAR(ADD_MONTHS(v_rebased_dtm,12), 'YY')
          WHEN v_interval = 'MM' THEN TO_CHAR(in_dtm, 'Month')
          WHEN v_interval = 'Q' THEN TRIM(v_interval) || TO_CHAR(FLOOR(v_rebased_month_num / 3)+1)
          WHEN v_interval = 'H' THEN TRIM(v_interval) || TO_CHAR(FLOOR(v_rebased_month_num / 6)+1)
          ELSE 'unknown'
        END
        INTO v_out
        FROM DUAL;
    RETURN v_out;
END;  

/** This is designed to return dates to the pivot table code which are sortable, but also contain
    a nicely formatted period too. The string returned is sortable, but if you split it on | then
    the second part of the string is the nicely formatted bit
  */
FUNCTION GetSortableRebasedDate(
    in_dtm      IN DATE, 
    in_base_dtm IN DATE, 
    in_interval IN CHAR
) RETURN VARCHAR2
AS
    v_interval CHAR(2);
    v_out VARCHAR2(255);
    v_base_start_month_num  NUMBER(2);
    v_rebased_month_num   NUMBER(2);
    v_rebased_dtm   DATE;
BEGIN
    -- rebase date donated as if year ran jan->jan (i.e. -2+1 = -1)
    v_base_start_month_num := TO_NUMBER(TO_CHAR(in_base_dtm,'MM'));
    -- TODO: fix this to truncate half-yearly (i.e. truncate to quarter then floor(x/2))
    v_rebased_dtm := TRUNC(  ADD_MONTHS(in_dtm, -v_base_start_month_num+1 ), in_interval);
    v_interval := UPPER(in_interval);
    v_rebased_month_num := TO_NUMBER(TO_CHAR(v_rebased_dtm,'MM'))-1;
    SELECT 
        CASE 
          WHEN v_interval = 'Y' AND v_base_start_month_num = 1 THEN 
                TO_CHAR(v_rebased_dtm, 'YYYY')||'|'||TO_CHAR(v_rebased_dtm, 'YYYY')
          WHEN v_interval = 'Y' AND v_base_start_month_num != 1 THEN 
                TO_CHAR(v_rebased_dtm, 'YYYY')||'|'||TO_CHAR(v_rebased_dtm, 'YY')||'/'||TO_CHAR(ADD_MONTHS(v_rebased_dtm,12), 'YY')
          WHEN v_interval = 'MM' THEN 
                lpad(v_rebased_month_num, 2,'0')||'|'||TO_CHAR(in_dtm, 'Month') 
                -- we no longer show the month because if you have two budget years with different
                -- start dates (feb+july), then February and July will both represent month 1 - the
                -- sorted output then looks really odd (July appears twice, once after February etc...)
                --lpad(v_rebased_month_num, 2,'0')||'|'||'Month '||(v_rebased_month_num+1)
          WHEN v_interval = 'Q' THEN 
                lpad(v_rebased_month_num, 2,'0')||'|'||TRIM(v_interval) || TO_CHAR(FLOOR(v_rebased_month_num / 3)+1)
          WHEN v_interval = 'H' THEN 
                lpad(v_rebased_month_num, 2,'0')||'|'||TRIM(v_interval) || TO_CHAR(FLOOR(v_rebased_month_num / 6)+1)
          ELSE 'unknown'
        END
        INTO v_out
        FROM DUAL;
    RETURN v_out;
END;   

PROCEDURE HasConstants(
    out_cur     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT
            CASE 
                WHEN  count(*) > 0 THEN 1 
                ELSE 0 
            END has_constants 
          FROM donations.constant 
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetConstants(
    out_cur     OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT constant_Id, lookup_key 
		  FROM donations.constant
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE QueueRecalc
AS
BEGIN
	QueueRecalc(SYS_CONTEXT('SECURITY', 'APP'));
END;


PROCEDURE QueueRecalc(
	in_app_sid		security_pkg.T_SID_ID	
)
AS
BEGIN
	BEGIN
		INSERT INTO donations.customer_recalc (app_sid, processing)
			VALUES (in_app_sid, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore if already queued
	END;
END;


PROCEDURE GetAppsToRecalc(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT app_sid 
		  FROM customer_recalc;
END;

PROCEDURE BeginAppRecalc
AS	
BEGIN
	-- clean any existing jobs where we have new ones to process
	DELETE FROM donations.customer_recalc
	 WHERE processing = 1
	   AND app_sid IN (
			SELECT app_sid 
			  FROM donations.customer_recalc
			 WHERE processing = 0
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  );
	
	UPDATE donations.customer_recalc
	   SET processing = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EndAppRecalc
AS	
BEGIN
	DELETE FROM donations.customer_recalc
	 WHERE processing = 1
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE EnableDonations(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID
)
AS
	v_done	number(10) := 0;
BEGIN
	BEGIN
		insert into donations.customer_filter_flag 
			(app_sid, RECIPIENT_REGION_GROUP, BROWSE_REGION_GROUP, REPORT_REGION_GROUP)
		values (in_app_sid, 0,1,0);
	EXCEPTION 	
		WHEN DUP_VAL_ON_INDEX THEN
			v_done := 1;
	END;
	
	IF v_done = 1 THEN
		RETURN;
	END IF;
	
	-- This is from Donations basedata... Try to insert these now (for some strange reason this SP is called from CreateSite
	-- on 'Create'... If donations hasn't previously been enabled, site creation will fail as we won't have any donations
	-- currencies setup! (Blows up for customers who are hosting product themselves).
	BEGIN
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'GBP', unistr('\20A4'), 'British Pound'); 
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'CZK', 'Kc', 'Czech Republic Korun'); 
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'EUR', unistr('\20AC'), 'Euro'); 
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'RUB', NULL, 'Russian Rubles'); 
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'NOK', 'kr', 'Norwegian Kroner'); 
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'AUD', '$', 'Australian Dollar'); 
		INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'USD', '$', 'US Dollar'); 
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	-- insert into currencies
	-- values from google, but easy enough to set on budget setup screen
	INSERT INTO donations.customer_default_exrate (currency_code, exchange_rate, app_sid)
			VALUES ('GBP',1,in_app_sid);
	INSERT INTO donations.customer_default_exrate (currency_code, exchange_rate, app_sid)
			VALUES ('USD',0.615195325,in_app_sid);
	INSERT INTO donations.customer_default_exrate (currency_code, exchange_rate, app_sid)
			VALUES ('EUR',0.860719779,in_app_sid);
	
	-- insert default custom_field sets
	-- NOTE
	-- it uses hard coded 13 as value for hour rate. It's easy to amend this using editField page.
	-- This approach doesn't involve setting constants for each new budget, which makes donations module quicker to be able to demo	
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,1,'Staff volunteering (outside work)',NULL,0,NULL,'time_hours_nonwork',0,'Enter the total number of hours volunteered by staff during non-work time.','time',11);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,2,'Total value of staff time given','(time_hours + time_hours_nonwork) * 13',0,'Automatically calculated when you save','value_of_time_given',1,NULL,'time',14);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,3,'Leverage',NULL,0,NULL,'leverage_total',1,'This is the total of all benefits generated through third parties such as customers or suppliers','leverage',7);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,4,'Total giving','cash_value + (((time_hours + time_hours_nonwork) * 13) + in_kind + leverage_total) - management_costs',0,'Automatically calculated when you save','total_company_contrib',1,'The sum of all company contributions and leveraged contributions',NULL,12);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,5,'Total value of expenditure','cash_value + ((time_hours + time_hours_nonwork) * 13) + in_kind',0,NULL,'total_contributions',1,'This is the total of all cash, time and stuff given by the company, but does not include leveraged benefits',NULL,13);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,11,'Cash contributions',NULL,0,'Include additional costs associated with a project, such as payments for materials used in volunteering, paying third party people to provide assistance.','cash_value',1,'Cash amounts may include direct donations to national or local appeals and sponsorship of causes or events','cash',5);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,6,'Number of employees volunteering',NULL,0,'DO NOT INCLUDE outsourced employees'', temps'' or contractors'' time','staff_qty',0,'Enter the number of staff who have participated in the activity during work time.','time',9);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,7,'Staff volunteering (during work)',NULL,0,NULL,'time_hours',0,'Enter the total number of hours volunteered by staff during work time.','time',10);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,8,'Gifts-in-kind',NULL,0,NULL,'in_kind',1,'This is the total of all in-kind benefits given by the company','inkind',6);
	INSERT INTO donations.custom_field (APP_SID,FIELD_NUM,LABEL,EXPR,IS_MANDATORY,NOTE,LOOKUP_KEY,IS_CURRENCY,DETAILED_NOTE,SECTION,POS) values (in_app_sid,9,'Management Costs',NULL,0,NULL,'management_costs',1,'In order that consistent comparisons can be made please exclude management costs from this breakdown',NULL,8);

	END;
END sys_Pkg;
/
