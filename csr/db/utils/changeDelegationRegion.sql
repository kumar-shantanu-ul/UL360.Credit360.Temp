/*
 Script	that moves a delegation to a different region,  give it the top level delegation, the current region sid and the new region sid. It will move the delegation then move the delegations subdelegations too.
*/

CREATE OR REPLACE PROCEDURE CSR.MoveDelegation(
  in_delegation_id       IN security_pkg.T_SID_ID, 
	in_current_region_id	 IN security_pkg.T_SID_ID,
	in_new_region_id		   IN security_pkg.T_SID_ID
) AS
BEGIN
	user_pkg.logonadmin('&host');
  
  --The below can be used to keep the original regions name, this was used to have the delegation at property level but have city levels name.
  --DELETE FROM Delegation_region_description WHERE Delegation_sid = in_delegation_id AND region_sid = in_current_region_id;
  --DELETE FROM Delegation_region_description WHERE Delegation_sid = in_delegation_id AND region_sid = in_new_region_id;
  --INSERT INTO delegation_region_description(DELEGATION_SID, REGION_SID, LANG, DESCRIPTION) SELECT in_delegation_id, in_new_region_id, lang, --description from region_description where region_sid = in_current_region_id;
  
	UPDATE Delegation_region 
	   SET region_sid = in_new_region_id, aggregate_to_region_sid = in_new_region_id 
     WHERE region_sid = in_current_region_id 
	   AND delegation_sid = in_delegation_id;
  
	UPDATE SHEET_VALUE 
       SET region_sid = in_new_region_id 
     WHERE region_sid = in_current_region_id
       AND sheet_id in (select sheet_id from sheet where delegation_sid = in_delegation_id);
     
	UPDATE sheet_value_change
       SET region_sid = in_new_region_id 
     WHERE region_sid = in_current_region_id
       AND sheet_value_id in (select sheet_value_id from sheet_value sv join sheet s on sv.sheet_id = s.sheet_id where delegation_sid = in_delegation_id);
     
	UPDATE VAL 
       SET region_sid = in_new_region_id 
     WHERE region_sid = in_current_region_id
       AND ind_sid in (select ind_sid from delegation_ind where delegation_sid = in_delegation_id)
       AND (period_start_dtm, period_end_dtm) in (select start_dtm, end_dtm from sheet where delegation_sid = in_delegation_id);
     
	UPDATE VAL_CHANGE 
       SET region_sid = in_new_region_id 
     WHERE region_sid = in_current_region_id
       AND ind_sid in (select ind_sid from delegation_ind where delegation_sid = in_delegation_id)
       AND (period_start_dtm, period_end_dtm) in (select start_dtm, end_dtm from sheet where delegation_sid = in_delegation_id);
     
	UPDATE VAL_NOTE 
       SET region_sid = in_new_region_id 
     WHERE region_sid = in_current_region_id
       AND ind_sid in (select ind_sid from delegation_ind where delegation_sid = in_delegation_id)
       AND (period_start_dtm, period_end_dtm) in (select start_dtm, end_dtm from sheet where delegation_sid = in_delegation_id);
   
	FOR r IN (SELECT d.Delegation_sid FROM Delegation d join delegation_region dr on d.delegation_sid = dr.delegation_sid where d.parent_sid = in_delegation_id and dr.region_sid = in_current_region_id)
	LOOP
		CSR.MoveDelegation(r.delegation_sid, in_current_region_id, in_new_region_id);
	END LOOP;
END;
/

EXEC CSR.MoveDelegation(&delegation_sid, &current_region, &new_region);


DROP PROCEDURE CSR.MoveDelegation;