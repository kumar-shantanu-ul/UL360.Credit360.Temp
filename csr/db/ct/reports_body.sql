CREATE OR REPLACE PACKAGE BODY ct.reports_pkg AS

PROCEDURE PSItemReport(
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_result_cur FOR
		SELECT item.item_id, item.description, item.spend,	         
		       curr.description currency, b.description business_structure, r.description region, item.purchase_date,
		       supplier.name as supplier_name, supplier.description as supplier_reference, item.kg_co2
		  FROM v$ps_item item
		  LEFT JOIN supplier 
		    ON item.app_sid = supplier.app_sid 
		   AND item.supplier_id = supplier.supplier_id
		  JOIN currency curr
		    ON curr.currency_id = item.currency_id
		  JOIN breakdown b
		    ON b.breakdown_id = item.breakdown_id
		  JOIN region r
		    ON r.region_id = item.region_id
		 ORDER BY spend_in_company_currency DESC;
END;

END  reports_pkg;
/
