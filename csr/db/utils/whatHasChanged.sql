exec user_pkg.logonadmin('iadb.credit360.com');

WITH ch AS (
    SELECT * 
      FROM (
        SELECT vc.*, 
            ROW_NUMBER() OVER (PARTITION BY vc.ind_sid, vc.region_sid, vc.period_start_dtm, vc.period_end_dtm ORDER BY val_change_id DESC) rn,
            LAG(val_number) OVER (PARTITION BY vc.ind_sid, vc.region_sid, vc.period_start_dtm, vc.period_end_dtm ORDER BY val_change_id DESC) prev_val_number,
            cu.full_name, r.description region, i.aggregate, st.description source_description
          FROM val_change vc
            JOIN csr_user cu ON cu.csr_user_sid = vc.changed_by_sid
            JOIN region r ON r.region_sid = vc.region_sid
            JOIN ind i ON i.ind_sid = vc.ind_sid
            JOIN source_type st ON vc.source_type_id = st.source_type_id
         WHERE period_start_dtm >= '1 jan 2008' AND period_end_dtm <='1 jan 2009'
           AND vc.source_type_id != 5
      )
      WHERE changed_dtm > '28 jul 2010'
     ORDER BY ind_sid, region_sid, period_start_dtm, period_end_dtm, rn asc
  )
SELECT LTRIM(indicator_pkg.INTERNAL_GetIndPathString(ind_sid),'Indicators / ') ind,
    region, 
    val_pkg.FormatPeriod(period_start_dtm, period_end_dtm, NULL) period,
    aggregate,
    ROW_NUMBER() OVER (PARTITION BY ind_sid, region_sid, period_start_dtm, period_end_dtm ORDER BY val_change_id DESC) rn,
    full_name changed_by, 
    source_description,
    changed_dtm changed_on,
    val_number set_to_value,
    prev_val_number from_value,
    reason
  FROM ch
 ORDER BY ind_sid, region_sid, period_start_dtm, period_end_dtm, rn ASC
;
