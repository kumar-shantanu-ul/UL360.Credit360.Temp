declare
    v_days          NUMBER;
    v_dtm           DATE;
    v_avg           NUMBER;
    v_reading       csr.meter_reading.val_number%TYPE;
    v_reading_id    csr.meter_reading.meter_reading_id%TYPE;
begin
	-- ensure we have data for the last 600 days or so for all point-in-time meters
	-- Data is inserted roughly fitting a curve appropriate for the northern hemisphere
	security.user_pkg.logonadmin('&&1');
    for r in (
        select m.region_sid, min(reading_dtm) min_reading_dtm, max(reading_dtm) max_reading_dtm, 
            nvl(min(val_number),0) min_val_number, nvl(max(val_number),0) val_number
          from csr.meter m
            join csr.meter_source_type mst on m.meter_source_type_id = mst.meter_source_type_id
            left join csr.meter_reading mr on m.region_sid = mr.region_sid
         where mst.manual_data_entry = 1 and mst.arbitrary_period = 0
         group by m.region_sid
    )
    loop
        v_dtm := NVL(r.max_reading_dtm, SYSDATE - 600);
        v_avg := (r.val_number - r.min_val_number) / (1 + r.max_reading_dtm - r.min_reading_dtm);
        if nvl(v_avg, 0) = 0 then
            v_avg := 1000;
        end if;
        v_reading := NVL(r.val_number,0);
        while v_dtm < SYSDATE-20
        loop
            v_days := round(dbms_random.value(1, 30));
            v_dtm := v_dtm + v_days;
            v_reading := v_reading + ROUND(v_days * v_avg * dbms_random.value(0.7, 1.5) * 
                (1.4 - sin( ((v_dtm - TRUNC(v_dtm, 'yyyy'))/ 365 ) * 3.141 ) )) ;
            csr.meter_pkg.SetMeterReading(security_pkg.getact, r.region_Sid, SYSDATE, null, 
                v_dtm, v_reading, null, null, null, null, null, v_reading_id); 
        end loop;
    end loop;
end;
/