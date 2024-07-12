-- Please update version.sql too -- this keeps clean builds in sync
define version=2188
@update_header

ALTER TABLE CHEM.SUBSTANCE_PROCESS_USE ADD (
     CHANGED_SINCE_PREV_PERIOD NUMBER(1) DEFAULT 0 NOT NULL,
     CONSTRAINT CHK_SUBS_PR_USE_CH_PP CHECK (CHANGED_SINCE_PREV_PERIOD IN (0,1)) );
	 
@../chem/report_body.sql
@../chem/substance_body.sql

BEGIN

	UPDATE CHEM.substance_process_use
	  SET CHANGED_SINCE_PREV_PERIOD = 1
	WHERE SUBSTANCE_PROCESS_USE_ID IN
	(
	  select 
		spu.SUBSTANCE_PROCESS_USE_ID 
	  from 
		chem.substance_process_use spu 
	   JOIN 
		chem.substance_process_use_change spuc 
		  ON spu.ROOT_DELEGATION_SID = spuc.ROOT_DELEGATION_SID
		  AND spu.SUBSTANCE_ID = spuc.SUBSTANCE_ID
		  AND spu.START_DTM = spuc.START_DTM
		  AND spu.END_DTM = spuc.END_DTM
		  AND spu.REGION_SID = spuc.REGION_SID
		  AND spu.APP_SID = spuc.APP_SID
	   LEFT JOIN chem.subst_process_cas_dest_change spcdc 
		  ON spcdc.SUBST_PROC_USE_CHANGE_ID = spuc.SUBST_PROC_USE_CHANGE_ID
	  GROUP BY spu.SUBSTANCE_PROCESS_USE_ID, spu.process_id, spuc.process_id
	  having 
		  COUNT(spcdc.SUBST_PROC_USE_CHANGE_ID)> 0 
		OR
		  spu.process_id != spuc.process_id
	);
	
END;
/

@update_tail