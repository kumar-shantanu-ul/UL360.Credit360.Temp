-- Please update version.sql too -- this keeps clean builds in sync
define version=1322
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

-- UK_FLOW_STATE_LOOKUP is in the model but not on live.
-- whack a random set of duplicates, then create the constraint
declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_indexes
	 where owner='CSR' and index_name='UK_FLOW_STATE_LOOKUP';
	if v_exists = 0 then
		update csr.flow_state
		   set lookup_key = null
		 where rowid in (
		 	select rid
		 	  from (
		 	  	select rowid rid,
		 	  		   row_number() over (partition by app_sid, flow_sid, upper(lookup_key) order by rowid) rn
		 	  	  from csr.flow_state
				 where lookup_key is not null)
			  where rn != 1);
		execute immediate 'CREATE UNIQUE INDEX CSR.UK_FLOW_STATE_LOOKUP ON CSR.FLOW_STATE(APP_SID, FLOW_SID, NVL(UPPER(LOOKUP_KEY),''FLST''||TO_CHAR(FLOW_STATE_ID)))';
	end if;
end;
/

@update_tail
