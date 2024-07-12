-- Please update version.sql too -- this keeps clean builds in sync
define version=727
@update_header

ALTER TABLE csr.REGION ADD (
    EGRID_REF_OVERRIDDEN    NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CHECK (EGRID_REF_OVERRIDDEN IN (0,1))
);

declare
	v_count	number(10) := 0;
begin
	for r in (
		select *
		  from (
			select app_sid, description, imp_ind_id, 
				FIRST_VALUE(imp_ind_id) over (partition by app_sid, lower(description) ORDER BY imp_ind_id) base_imp_ind_id,
				ROW_NUMBER() over (partition by app_sid, lower(description) ORDER BY imp_ind_id) rn
			  from csr.imp_ind
		 )x
		 where rn > 1
	)
	loop
		update csr.imp_measure
		   set imp_ind_id = r.base_imp_ind_id
		 where app_sid = r.app_sid and imp_ind_id = r.imp_ind_id;
		
		update csr.imp_val
		   set imp_ind_id = r.base_imp_ind_id
		 where app_sid = r.app_sid and imp_ind_id = r.imp_ind_id;	
			
		delete from csr.imp_ind where imp_ind_id = r.imp_ind_id;
		v_count := v_count + 1;
	end loop;
	dbms_output.put_line(v_count||' rows fixed.');
end;
/

declare
	v_count	number(10) := 0;
begin
	for r in (
		select *
		  from (
			select app_sid, description, imp_region_id, 
				FIRST_VALUE(imp_region_id) over (partition by app_sid, lower(description) ORDER BY imp_region_id) base_imp_region_id,
				ROW_NUMBER() over (partition by app_sid, lower(description) ORDER BY imp_region_id) rn
			  from csr.imp_region
		 )x
		 where rn > 1
	)
	loop
		update csr.imp_val
		   set imp_region_id = r.base_imp_region_id
		 where app_sid = r.app_sid and imp_region_id = r.imp_region_id;	
		 
		delete from csr.imp_region where imp_region_id = r.imp_region_id;
		v_count := v_count + 1;
	end loop;
	dbms_output.put_line(v_count||' rows fixed.');
end;
/


declare
	v_count	number(10) := 0;
begin
	for r in (
		select *
		  from (
			select app_sid, description, imp_measure_id, 
				FIRST_VALUE(imp_measure_id) over (partition by app_sid, imp_ind_id, lower(description) ORDER BY imp_measure_id) base_imp_measure_id,
				ROW_NUMBER() over (partition by app_sid, imp_ind_id, lower(description) ORDER BY imp_measure_id) rn
			  from csr.imp_measure
		 )x
		 where rn > 1
	)
	loop
		update csr.imp_val
		   set imp_measure_id = r.base_imp_measure_id
		 where app_sid = r.app_sid and imp_measure_id = r.imp_measure_id;		
		 
		delete from csr.imp_measure where imp_measure_id = r.imp_measure_id;
		v_count := v_count + 1;
	end loop;
	dbms_output.put_line(v_count||' rows fixed.');
end;
/

CREATE UNIQUE INDEX CSR.UK_IMP_IND_DESC ON CSR.IMP_IND(APP_SID, LOWER(DESCRIPTION));
CREATE UNIQUE INDEX CSR.UK_IMP_REGION_DESC ON CSR.IMP_REGION(APP_SID, LOWER(DESCRIPTION));
CREATE UNIQUE INDEX CSR.UK_IMP_MEASURE_DESC ON CSR.IMP_MEASURE(APP_SID, IMP_IND_ID, LOWER(DESCRIPTION));


@..\imp_body
@..\region_body

@update_tail