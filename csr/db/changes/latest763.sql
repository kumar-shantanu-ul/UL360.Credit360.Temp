-- Please update version.sql too -- this keeps clean builds in sync
define version=763
@update_header

update csr.val set aggr_est_number = null where aggr_est_number is not null;
alter table csr.val modify aggr_est_number number(10,0);
alter table csr.val rename column aggr_est_number to error_code;

CREATE OR REPLACE VIEW csr.val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, 
	error_code, alert, flags, source_id, entry_measure_conversion_id, entry_val_number, 
	note, source_type_id, factor_a, factor_b, factor_c, changed_by_sid, changed_dtm
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		   ROUND(NVL(NVL(mc.a, mcp.a), 1) * POWER(v.entry_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0),10) val_number,
		   v.error_code,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number,
		   v.note, v.source_type_id,
		   NVL(mc.a, mcp.a) factor_a,
		   NVL(mc.b, mcp.b) factor_b,
		   NVL(mc.c, mcp.c) factor_c,
		   v.changed_by_sid, v.changed_dtm
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);      

alter table csr.temp_new_val add error_code			number(10);
alter table csr.get_value_result add error_code		number(10);

-- add recalc jobs to populate val.error_code
begin
	for r in (select host, app_sid from customer) loop
		dbms_output.put_line('doing '||r.host||' ('||r.app_sid||')');
		update csr.calc_job_lock
		   set dummy = 1
		 where app_sid = r.app_sid;
		delete
		  from csr.stored_calc_job
		 where app_sid = r.app_sid
		   and processing = 0;
		insert into csr.stored_calc_job (app_sid, ind_sid, region_sid, start_dtm, end_dtm)
			select v.app_sid, v.ind_sid, v.region_sid, min(v.period_start_dtm), max(v.period_end_dtm)
			  from csr.val v
			 where v.app_sid = r.app_sid
			 group by v.app_sid, v.ind_sid, v.region_sid;
		commit;
	end loop;
end;
/

@../indicator_pkg
@../schema_pkg
@../calc_pkg
@../indicator_body
@../schema_body
@../calc_body
@../stored_calc_datasource_body
@../val_body
@../val_datasource_body

@update_tail
