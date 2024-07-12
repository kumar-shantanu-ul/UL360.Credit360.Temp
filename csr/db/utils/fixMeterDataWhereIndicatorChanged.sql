
DECLARE
BEGIN
    user_pkg.logonadmin('&&1');
    FOR r IN (
        SELECT *
          FROM (
            SELECT v.val_id, r.region_sid, 
                meter_pkg.INTERNAL_GetProperty(m.region_sid) property,
                NVL(m.REFERENCE, r.description) meter_ref,
                iv.description previous_ind,
                im.description current_meter_type,
                CASE WHEN m.primary_ind_sid != v.ind_sid THEN 'duff' ELSE 'kosher' END TYPE,
                period_start_dtm, period_end_dtm, val_number,
                CASE 
                    WHEN LEAD(v.period_start_dtm) OVER (
                        PARTITION BY v.region_sid, v.period_start_dtm 
                        ORDER BY v.region_sid, v.period_start_dtm, 
                            (CASE WHEN m.primary_ind_sid != v.ind_sid THEN 'duff' ELSE 'kosher' END)
                        ) = v.period_start_dtm THEN 1
                    ELSE 0
                END to_clean
              FROM val v
                JOIN region r ON v.region_sid = r.region_sid
                JOIN meter m ON r.region_sid = m.region_sid
                JOIN ind iv ON v.ind_sid = iv.ind_sid
                JOIN ind im ON m.primary_ind_sid = im.ind_sid
             WHERE r.region_sid IN (
                SELECT distinct r.region_sid
                  FROM val v
                    JOIN region r ON v.region_sid = r.region_sid
                    JOIN meter m ON r.region_sid = m.region_sid
                 WHERE v.source_Type_Id = 8
                   AND m.primary_ind_sid != v.ind_sid 
               )
               AND v.source_Type_Id = 8
             ORDER BY r.region_sid, v.period_start_dtm, TYPE
         )
         WHERE to_clean = 1
    )
    LOOP
        indicator_pkg.DeleteVal(security_pkg.getact, r.val_id, 'Overlapping meter reading');
    END LOOP;
END;
/