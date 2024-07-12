-- Please update version.sql too -- this keeps clean builds in sync
define version=628
@update_header

@../sheet_pkg
@../delegation_pkg
@../sheet_body
@../delegation_body
@../imp_body

-- fixes up duff sheet_inherited_value (again!)
create table csr.fb8111_deleted_val as 
	select * from val where 1=0;
create table csr.fb8111_inserted_val (app_sid number(10), val_id number(10));
create table csr.fb8111_deleted_siv as 
	select * from sheet_inherited_value where 1 = 0;
create table csr.fb8111_message (fb8111_message_id number(10), message varchar2(4000));
create sequence fb8111_message_id_seq;
create table csr.fb8111_val_to_delete (app_sid number(10), val_id number(10));
create table csr.fb8111_val_to_remerge (app_sid number(10), sheet_value_id number(10));

create or replace procedure csr.fb8111_log(
    in_msg				in varchar2
)
as
	pragma autonomous_transaction;
begin
    insert into fb8111_message (
    	fb8111_message_id,
		message
	) values (
		fb8111_message_id_seq.nextval,
		in_msg
	);
	commit;
end;
/

declare
	v_skip 							boolean;
	v_was_merged					boolean;
	v_file_uploads					security.security_pkg.T_SID_IDS;
	v_val_id						csr.val.val_id%TYPE;
	v_top_value_id					csr.sheet_value.sheet_value_id%type;
	v_is_inherited					csr.sheet_value.is_inherited%TYPE;
	v_inherited_count				number;
begin
    for c in (select host from csr.customer) loop
    	begin
        	security.user_pkg.logonadmin(c.host);
        	v_skip := false;
        exception 
        	when security.security_pkg.object_not_found then
		        fb8111_log('skipping host with no website: '||c.host);
        		v_skip := true;
        end;

		if not v_skip then
			for cs in (
                select distinct sheet_id child_sheet_id, parent_sheet_id, lvl
                  from (select s.sheet_id, prior s.sheet_id parent_sheet_id, level lvl
					   	  from csr.delegation d, csr.sheet s
					     where s.app_sid = d.app_sid and s.delegation_sid = d.delegation_sid
					           start with d.parent_sid = d.app_sid
					           connect by prior d.app_sid = d.app_sid and prior d.delegation_sid = d.parent_sid)
				 where parent_sheet_id is not null
			  	 order by lvl desc) loop

				for r in (
					select /*+ALL_ROWS*/ esv.sheet_value_id
					  from (
							SELECT /*+ALL_ROWS*/ sheet_id, ind_sid, aggregate_to_region_sid, aggregate, is_regional_aggregation,
								CASE 
									WHEN MIN(entry_measure_conversion_id) = -1 THEN NULL -- see below - we swap NULL -> -1 for aggregations
									WHEN MAX(distinct_emc_id) = 1 AND COUNT(DISTINCT entry_measure_conversion_id) = 1 THEN MIN(entry_measure_conversion_id) 
									ELSE NULL 
								END entry_measure_conversion_id,
								-- 0 = indivisible (average), 1 = divisible (sum), 2 = indivisible (last_period) - we use MIN since we already figured out the last period in the inner query
								CASE divisible WHEN 0 THEN avg(sum_val_number) WHEN 1 THEN SUM(sum_val_number) WHEN 2 THEN MIN(sum_last_val_number) END val_number,
								CASE divisible WHEN 0 THEN avg(sum_entry_val_number) WHEN 1 THEN SUM(sum_entry_val_number) WHEN 2 THEN MIN(sum_last_entry_val_number) END entry_val_number,
								MIN(flag) flag
					  	      FROM (
								  SELECT sheet_id, ind_sid, divisible, aggregate, is_regional_aggregation, aggregate_to_region_sid, start_dtm, end_dtm,
										 MIN(entry_measure_conversion_Id) entry_measure_conversion_id,
										 COUNT(DISTINCT entry_measure_conversion_id) distinct_emc_id,	
										 SUM(val_number) sum_val_number, SUM(entry_val_number) sum_entry_val_number, -- sum regions as we aggregate
										 SUM(last_val_number) sum_last_val_number, SUM(last_entry_val_number) sum_last_entry_val_number,
										 MIN(flag) flag
								    FROM (
									  SELECT sp.sheet_id, sv.ind_sid, i.divisible, i.aggregate, sdr.aggregate_to_region_sid, s.start_dtm, s.end_dtm, 
											 CASE WHEN sdr.region_sid != sdr.aggregate_to_region_sid THEN 1 ELSE 0 END is_regional_aggregation,
											 -- if we're aggregating regions, then tag on the source of any notes
											 CASE WHEN sv.note IS NULL THEN NULL WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN sv.note ELSE sv.note||' ('||sdr.description||')' END note,
											 -- if we're not aggregating then use the value WITHOUT taking pct_ownership into account since this will get reapplied WHEN we store it
											 CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN val_number ELSE actual_val_number END val_number,
											 CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN entry_val_number ELSE entry_val_number * region_pkg.GetPctOwnership(sv.ind_sid, sv.region_sid, s.start_dtm)  END entry_val_number,
											 NVL(entry_measure_conversion_id,-1) entry_measure_conversion_id, -- NVL because NULL gets discarded by aggregate
											 -- figure out the "last_val_number" stuff here in case that's how we're aggregating
											 FIRST_VALUE(CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN val_number ELSE actual_val_number END) 
												OVER (PARTITION BY sp.sheet_id, sv.ind_sid, i.divisible, sdr.aggregate_to_region_sid, sdr.region_sid ORDER BY s.start_dtm DESC) last_val_number,
											 FIRST_VALUE(CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN entry_val_number ELSE entry_val_number * region_pkg.GetPctOwnership(sv.ind_sid, sv.region_sid, s.start_dtm) END) 
												OVER (PARTITION BY sp.sheet_id, sv.ind_sid, i.divisible, sdr.aggregate_to_region_sid, sdr.region_sid ORDER BY s.start_dtm desc) last_entry_val_number,
											 sheet_value_id, -- for accuracy copying 
											 sv.flag
							 			FROM -- Parent sheet (merging to)
							 				 csr.sheet sp, 
							 				 -- Child sheet (merging from)
							 				 csr.sheet sc, 
							 				 -- Sheets on sibling delegations
							 				 csr.sheet s, 
							 				 -- Values on those sheets
							 				 csr.sheet_value_converted sv, 
							 				 -- Inds on the child sheet
							 				 csr.delegation_ind cdi, 
							 				 -- Regions on the sibling sheet
							 				 csr.delegation_region sdr,
					                         -- Inds on the parent sheet
					                         csr.delegation_ind pdi,
					                         -- Inds on the sibling sheet
					                         csr.delegation_ind sdi,
							 				 -- All regions on the child sheet that are aggregated to
							 				 -- This is used to pick up sibling sheets that aggregate to the same region
					                         (SELECT DISTINCT dr.app_sid, dr.aggregate_to_region_sid
					                            FROM csr.delegation_region dr, sheet csr.s
					                           WHERE s.app_sid = dr.app_sid 
					                             AND s.delegation_sid = dr.delegation_sid
					                             AND s.sheet_id = cs.child_sheet_id) cdr,
					                         -- Sibling sheet delegation
					                         csr.delegation sd, 
					                         -- Inds, regions mapped to sheet values
					                         csr.region r, csr.ind i						 
									   WHERE sp.sheet_id = cs.parent_sheet_id
										 AND sc.sheet_id = cs.child_sheet_id
										 -- Pick up indicators on the child sheet
										 AND cdi.app_sid = sc.app_sid AND cdi.delegation_sid = sc.delegation_sid
										 -- Pick up regions on the sibling sheet
										 AND sdr.app_sid = s.app_sid AND sdr.delegation_sid = s.delegation_sid
										 -- Constrain to regions that we aggregate to
										 AND cdr.app_sid = sdr.app_sid AND cdr.aggregate_to_region_sid = sdr.aggregate_to_region_sid
										 -- Join to ind, region
										 AND i.app_sid = cdi.app_sid AND i.ind_sid = cdi.ind_sid
										 AND r.app_sid = sdr.app_sid AND r.region_sid = sdr.region_sid
										 -- Join to sheet value
										 AND sv.app_sid = cdi.app_sid AND sv.ind_sid = cdi.ind_sid
										 AND sv.app_sid = sdr.app_sid AND sv.region_sid = sdr.region_sid
										 -- Child sheets of the parent delegation
										 AND s.app_sid = sp.app_sid
										 AND s.start_dtm >= sp.start_dtm
										 AND s.end_dtm <= sp.end_dtm
										 AND s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
										 AND sd.app_sid = s.app_sid AND sd.delegation_sid = s.delegation_sid
										 AND sd.app_sid = sp.app_sid AND sd.parent_sid = sp.delegation_sid
					                     -- Ensure inds actually exist on the parent/sibling sheet (they may not, we keep deleted data)
					                     AND sp.app_sid = pdi.app_sid AND sp.delegation_sid = pdi.delegation_sid
					                     AND sv.app_sid = pdi.app_sid AND sv.ind_sid = pdi.ind_sid
					                     AND sdi.app_sid = s.app_sid AND sdi.delegation_sid = s.delegation_sid
					                     AND sv.app_sid = sdi.app_sid AND sv.ind_sid = sdi.ind_sid
										)					
									   GROUP BY sheet_id, ind_sid, divisible, aggregate, is_regional_aggregation, aggregate_to_region_sid, start_dtm, end_dtm
								)
							 --WHERE (is_regional_aggregation = 0 OR (is_regional_aggregation = 1 AND aggregate IN ('SUM','FORCE SUM')))
							 GROUP BY sheet_id, ind_sid, divisible, aggregate, is_regional_aggregation, aggregate_to_region_sid) nsv,
							   (SELECT sv.sheet_value_id, sv.ind_sid, sv.region_sid, sv.val_number
							   	  FROM sheet_value sv, delegation_ind di, delegation_region dr, sheet s
							   	 WHERE s.sheet_id = cs.parent_sheet_id
							   	   AND s.app_sid = di.app_sid AND s.delegation_sid = di.delegation_sid
							   	   AND s.app_sid = dr.app_sid AND s.delegation_sid = dr.delegation_sid
							   	   AND di.app_sid = sv.app_sid AND di.ind_sid = sv.ind_sid
							   	   AND dr.app_sid = sv.app_Sid AND dr.region_sid = sv.region_sid
							   	   AND s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id) esv
				   	   WHERE nsv.ind_sid = esv.ind_sid
				   	     AND nsv.aggregate_to_region_sid = esv.region_sid
				   	     AND nsv.val_number != esv.val_number) loop

					fb8111_log('checking ' ||r.sheet_value_id);
					
					-- check whether this is a false positive: i.e. where it's already not inherited
					select is_inherited
					  into v_is_inherited
					  from csr.sheet_value
					 where sheet_value_id = r.sheet_value_id;

					-- but is_inherited is wrong (sometimes?) so check that as well...
					select count(*)
					  into v_inherited_count
					  from csr.sheet_inherited_value
					 where sheet_value_id = r.sheet_value_id;
					 					 
					if v_is_inherited = 1 or v_inherited_count > 0 then
						-- find the top level value to merge 
						-- begin
							select sheet_value_id
							  into v_top_value_id
							  from (select sheet_value_id, rownum rn
									  from (select sheet_value_id
											  from csr.sheet_inherited_value
											  	   start with sheet_value_id = r.sheet_value_id
											  	   connect by prior app_sid = app_sid and prior sheet_value_id = inherited_value_id
											  	   order by level desc))
							 where rn = 1;
						--exception
						--	when no_data_found then
						--		fb8111_log('******** ffs. '||r.sheet_value_id);
						--end;
					
						-- clear out the merged inherited values: these will incorrectly be from the lowest level of the sheet
						v_was_merged := false;
						for rv in (select v.val_id, sv.inherited_value_id
									 from val v, (select sv.app_sid, sv.inherited_value_id
									 				from csr.sheet_inherited_value sv
									 					 start with sv.sheet_value_id = r.sheet_value_id
										  				 connect by prior sv.app_sid = sv.app_sid and prior sv.inherited_value_id = sv.sheet_value_id) sv
									where v.app_sid = sv.app_sid and v.source_type_id = 1 and v.source_id = sv.inherited_value_id) loop
	
							fb8111_log('cleared out merged inherited value with val_id = '||rv.val_id||' and sheet_value_id = '||rv.inherited_value_id);
							
							/* this would fix the data, but it's commented out so we don't change historical data
							   the intention is to review the messed up data and remerge after review if required
							   
							-- back it up
							insert into fb8111_deleted_val
								select *
								  from val 
								 where val_id = rv.val_id;
							  
							indicator_pkg.deleteVal(sys_context('security', 'act'), rv.val_id, 'Clearing incorrectly merged value');
							*/
							insert into csr.fb8111_val_to_delete
								(app_sid, val_id)
							values
								(sys_context('security', 'app'), rv.val_id);
														
							v_was_merged := true;
						end loop;
	
						-- back up the inheritance chain
						insert into csr.fb8111_deleted_siv
							select *
							  from csr.sheet_inherited_value
							 where sheet_value_id = r.sheet_value_id;
							 
						-- break the inheritance chain
						delete 
						  from csr.sheet_inherited_value 
						 where sheet_value_id = r.sheet_value_id;
	
						update sheet_value
						   set csr.is_inherited = 0
						 where sheet_value_id = r.sheet_value_id;
						 
						fb8111_log('broke inheritance chain for sheet_value_id = '||r.sheet_value_id);
						 
						-- if this is top level and the values were merged, then merge the value
						if v_was_merged then
							for sv in (select s.start_dtm, s.end_dtm, sv.ind_sid, sv.region_sid, sv.val_number, sv.sheet_value_id,
											  sv.entry_measure_conversion_id, sv.entry_val_number, sv.note
										 from csr.sheet_value sv, csr.sheet s
										where sv.sheet_value_id = v_top_value_id
										  and sv.app_sid = s.app_sid and sv.sheet_id = s.sheet_id) loop
	
								insert into csr.fb8111_val_to_remerge
									(app_sid, sheet_value_id)
								values
									(sys_context('security', 'app'), sv.sheet_value_id);
									
								/* See note above: we are not actually changing merged data yet
								select file_upload_sid
								  bulk collect into v_file_uploads
								  from sheet_value_file
								 where sheet_value_id = v_top_value_id;
		
								indicator_pkg.SetValueWithReasonWithSid(
									in_user_sid => SYS_CONTEXT('SECURITY', 'SID'), 
									in_ind_sid => sv.ind_sid, 
									in_region_sid => sv.region_sid, 
									in_period_start => sv.start_dtm, 
									in_period_end => sv.end_dtm, 
									in_val_number => sv.val_number, 
									in_flags => 0, 
									in_source_type_id => csr_data_pkg.SOURCE_TYPE_DELEGATION,
									in_source_id => sv.sheet_value_id, 
									in_entry_conversion_id => sv.entry_measure_conversion_id, 
									in_entry_val_number => sv.entry_val_number, 
									in_aggr_est_number => NULL, 
									in_update_flags => 0, 
									in_reason => 'Merged correct value',
									in_note => sv.note, 
									in_have_file_uploads => 1, 
									in_file_uploads => v_file_uploads, 
									out_val_id => v_val_id);
									
								insert into fb8111_inserted_val
									(app_sid, val_id) 
								values
									(sys_context('security', 'app'), v_val_id);
								*/
								fb8111_log('merged sheet value id '||v_top_value_id||' to value with id '||v_val_id||' (val_number = '||sv.val_number||')');
							end loop;
						end if;
					end if;
				end loop;
			end loop;
			
			-- fix up things that are marked as not inherited, but have correct SIVs
			for r in (select sv.sheet_value_id
						from csr.sheet_value sv, csr.sheet_inherited_value siv
					   where sv.app_sid = siv.app_sid and sv.sheet_value_id = siv.sheet_value_id
					     and sv.is_inherited = 0
					   group by sv.sheet_value_id) loop
				fb8111_log('set is_inherited flag for the value '||r.sheet_value_id);
				update csr.sheet_value
				   set is_inherited = 1
				 where sheet_value_id = r.sheet_value_id;
			end loop;
			
			-- and the other way around
			for r in (select sv.sheet_value_id
						from csr.sheet_value sv
					   where not exists (select 1
					   					   from csr.sheet_inherited_value siv
					   					  where sv.app_sid = siv.app_sid and sv.sheet_value_id = siv.sheet_value_id)
						 and sv.is_inherited = 1) loop

				fb8111_log('clear is_inherited flag for the value '||r.sheet_value_id);
				update sheet_value
				   set csr.is_inherited = 0
				 where sheet_value_id = r.sheet_value_id;					   					  
			end loop;
			
			-- release locks between hosts
			commit;
			
	        security_pkg.setapp(null);
		end if;        
    end loop;
end;
/

@update_tail
