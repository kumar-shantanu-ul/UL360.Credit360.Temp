CREATE OR REPLACE PACKAGE BODY SUPPLIER.report_pkg
IS

PROCEDURE SetReportSettings(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_period_id		IN user_report_settings.period_id%TYPE,
	in_show_unapproved	IN user_report_settings.show_unapproved%TYPE,
	in_sales_types		IN tag_pkg.T_TAG_IDS
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);
	
	-- Delete existing settings
	DELETE FROM user_report_sales_types
	 WHERE csr_user_sid = v_user_sid;
	
	DELETE FROM user_report_settings
	 WHERE csr_user_sid = v_user_sid;

	-- Insert new settings
	INSERT INTO user_report_settings
		(csr_user_sid, period_id, show_unapproved)
	  VALUES(v_user_sid, in_period_id, in_show_unapproved);
		 
	-- No support for "empty arrays"
	IF in_sales_types.COUNT = 1 AND in_sales_types(1) IS NULL THEN
		RETURN;
	END IF;
	
	-- Insert sales types
	FOR i IN in_sales_types.FIRST .. in_sales_types.LAST
	LOOP
		INSERT INTO user_report_sales_types
			(csr_user_sid, tag_id)
		  VALUES(v_user_sid, in_sales_types(i));
	END LOOP;
END;

PROCEDURE GetReportSettings(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT period_id, show_unapproved
		  FROM user_report_settings
		 WHERE csr_user_sid = v_user_sid;
END;

PROCEDURE GetReportSalesTypes(
	in_act_id			IN security_pkg.T_ACT_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSID(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT tag_id
		  FROM user_report_sales_types
		 WHERE csr_user_sid = v_user_sid;
END;

PROCEDURE RunSalesValueReport(
	in_act_id					IN 	security_pkg.T_ACT_ID,
	in_period_id				IN	period.period_id%TYPE,
	in_sales_type_tag_ids		IN 	utils_pkg.T_NUMBERS,
	in_report_on_unapproved 	NUMBER,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	
	t_items							csr.T_SPLIT_NUMERIC_TABLE;

BEGIN

	-- Check for NULL array
	IF in_sales_type_tag_ids IS NULL OR (in_sales_type_tag_ids.COUNT = 1 AND in_sales_type_tag_ids(1) IS NULL) THEN
        RAISE_APPLICATION_ERROR(product_pkg.ERR_NULL_ARRAY_ARGUMENT, 'Null array argument was passed');
	END IF;

	-- Security check for admin??
	-- TO DO
	
	-- load up temp_tag table
	t_items := csr.utils_pkg.NumericArrayToTable(in_sales_type_tag_ids);

	OPEN out_cur FOR
    SELECT prt.product_code, prt.product_id, prt.description, psv.volume, psv.value, 
    CASE 
        WHEN ((psv.volume IS NULL) AND (psv.value IS NULL)) THEN 'No sales value or volume set'
        WHEN (psv.volume IS NULL) THEN 'No sales volume set'
        WHEN (psv.value IS NULL) THEN 'No sales value set'
        ELSE NULL
    END  sales_data_status, DECODE(pq.wood_q_present, 1, 'Yes', 0, 'No') wood_q_present, DECODE(pq.nat_prod_q_present, 1, 'Yes', 0, 'No') nat_prod_q_present
    FROM 
    (
		SELECT p.product_code, p.product_id, p.description, MIN(DECODE(group_status_id, product_pkg.DATA_APPROVED, product_pkg.DATA_APPROVED, product_pkg.DATA_BEING_ENTERED)) product_status_id FROM product p, product_questionnaire_group pqg
		WHERE p.product_id = pqg.product_id
		GROUP BY p.product_code, p.product_id, p.description
    ) prt, (select * from product_sales_volume where period_id = in_period_id) psv, tag t, tag_group_member tgm, tag_group tg, product_tag pt, 
    (
        SELECT product_id, 
            MAX((CASE
                WHEN class_name = 'wood' THEN 1
                ELSE 0 
            END)) AS wood_q_present, 
            MAX((CASE
                WHEN class_name = 'naturalProduct' THEN 1
                ELSE 0 
            END)) AS nat_prod_q_present
            FROM product_questionnaire pq, questionnaire q
            WHERE pq.questionnaire_id = q.questionnaire_id  
        GROUP BY product_id 
    ) pq
        WHERE t.tag_id = tgm.tag_id
            AND tgm.tag_group_sid = tg.tag_group_sid
            AND tg.name = 'sale_type'
            AND pt.tag_id = t.tag_id
            AND prt.product_id = pt.product_id
            AND prt.product_id = psv.product_id(+)
            AND prt.product_id = pq.product_id
		    AND t.tag_id IN (SELECT item tag_id FROM TABLE(CAST(t_items AS csr.T_SPLIT_NUMERIC_TABLE))) -- in_sale_type_tag_id  
		    AND ((prt.product_status_id = product_pkg.DATA_APPROVED AND in_report_on_unapproved = 0) OR (in_report_on_unapproved <> 0)); -- in_report_only_on_approved  

END;


END report_pkg;
/
