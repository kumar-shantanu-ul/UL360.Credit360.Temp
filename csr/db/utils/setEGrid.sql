CREATE OR REPLACE PROCEDURE SetEgrid(
	in_region_sid					IN 	region.region_sid%TYPE,
	in_egrid_ref					IN	region.egrid_ref%TYPE
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	UPDATE region
	   SET egrid_ref = in_egrid_ref,
		   last_modified_dtm = SYSDATE
	 WHERE (app_sid, region_sid) IN (	 
			SELECT app_sid, region_sid
	 		  FROM region
			 START WITH region_sid = in_region_sid
           CONNECT BY PRIOR app_sid = app_sid 
			   AND PRIOR region_sid = parent_sid -- assuming we don't want to go down the secondary tree?
               AND egrid_ref_overridden = 0               
	);

	-- Add recalc jobs for any co2 indicators
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
	USING (SELECT i.app_sid, i.ind_sid, v_calc_start_dtm period_start_dtm, v_calc_end_dtm period_end_dtm
		     FROM ind i
		    WHERE i.gas_type_id IS NOT NULL) v
	   ON (v.app_sid = vcl.app_sid AND v.ind_sid = vcl.ind_sid)
	 WHEN MATCHED THEN
		UPDATE 
		   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
			   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
	 WHEN NOT MATCHED THEN
		INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
		VALUES (v.ind_sid, v.period_start_dtm, v.period_end_dtm);
END;
/

declare
	v_cnt number := 0;
begin
	user_pkg.logonadmin('greenprint.credit360.com');
	for r in (
		select r.region_sid, p.postcode, pe.egrid_ref
		  from region r 
		  join property p on r.region_sid = p.region_sid
		  join postcode_egrid pe on pe.country = r.geo_country and pe.postcode = p.postcode
		 where r.geo_country='us' and r.egrid_ref is null
	)
	loop
		SetEgrid(r.region_sid, r.egrid_ref);
		v_cnt := v_cnt + 1;
		commit;
	end loop;
	dbms_output.put_line(v_cnt||' done');
end;
/


DROP PROCEDURE SetEgrid;
