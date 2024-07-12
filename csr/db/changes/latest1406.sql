-- Please update version.sql too -- this keeps clean builds in sync
define version=1406
@update_header

/*v$ht_water_waste - water and waste consumption breakdown values UNION consumption default value (when breakdowns do not exist)*/
CREATE OR REPLACE VIEW ct.v$ht_water_waste (
    app_sid, company_sid, category_id, type_id, source_id, source_description, amount, unit_id, unit_type
)
AS
SELECT c.app_sid, c.company_sid, c.ht_consumption_category_id, c.ht_consumption_type_id, cs.ht_cons_source_id, cs.description, c.amount, NVL(c.volume_unit_id, c.mass_unit_id), DECODE(c.volume_unit_id, NULL, 1, 2) -- (consumption_pkg.MASS_UNIT, consumption_pkg.VOLUME_UNIT) 
  FROM ct.ht_consumption c
  JOIN ct.ht_cons_source cs ON (c.ht_consumption_category_id = cs.ht_consumption_category_id AND c.ht_consumption_type_id = cs.ht_consumption_type_id)
 WHERE c.ht_consumption_category_id IN (4, 5) -- (ct.consumption_pkg.WATER, ct.consumption_pkg.WASTE)
   AND cs.is_remainder = 1
   AND NOT EXISTS(
	SELECT 1
      FROM ct.ht_cons_source_breakdown csb   
     WHERE csb.app_sid = c.app_sid
       AND csb.company_sid = c.company_sid
       AND csb.ht_consumption_category_id = c.ht_consumption_category_id
       AND csb.ht_consumption_type_id = c.ht_consumption_type_id
   )
UNION
SELECT c.app_sid, c.company_sid, c.ht_consumption_category_id, c.ht_consumption_type_id, cs.ht_cons_source_id, cs.description, csb.amount, NVL(c.volume_unit_id, c.mass_unit_id), DECODE(c.volume_unit_id, NULL, 1, 2)
  FROM ct.ht_cons_source_breakdown csb 
  JOIN ct.ht_consumption c ON (c.ht_consumption_type_id = csb.ht_consumption_type_id AND c.ht_consumption_category_id = csb.ht_consumption_category_id AND c.app_sid = csb.app_sid AND c.company_sid = csb.company_sid)
  JOIN ct.ht_cons_source cs ON (cs.ht_cons_source_id = csb.ht_cons_source_id);

BEGIN
	UPDATE ct.volume_unit SET conversion_to_litres = '3.78541178' WHERE volume_unit_id= 2;
	UPDATE ct.volume_unit SET conversion_to_litres = '4.54609188' WHERE volume_unit_id= 3;
	UPDATE ct.mass_unit SET conversion_to_kg = '0.45359237' WHERE  mass_unit_id= 2;
END;
/


@..\ct\consumption_pkg
@..\ct\consumption_body

@..\ct\util_pkg
@..\ct\util_body

@..\ct\value_chain_report_pkg
@..\ct\value_chain_report_body

@update_tail
