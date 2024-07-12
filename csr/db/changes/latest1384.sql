-- Please update version.sql too -- this keeps clean builds in sync
define version=1384
@update_header

-- TODO: NEED TO ADD THESE TO THE SCHEMA (MDW i'll sort thx for sorting the other ones)
CREATE UNIQUE INDEX CSR.UK_STD_FACTOR ON CSR.STD_FACTOR (
	STD_FACTOR_SET_ID, FACTOR_TYPE_ID, NVL(GEO_COUNTRY, 'XX'), NVL(GEO_REGION, 'XX'), NVL(EGRID_REF, 'XX'), START_DTM, END_DTM, GAS_TYPE_ID
);


-- guff that's crept in due to Benny's inadequate code
-- (couple of factors in H and M on live - std_factor_id 1731,1677,5395,5422,1704,5449,4586,5476)
delete from csr.factor
 where (app_sid, factor_id) in (
 select app_sid, factor_id
   from (
        select app_sid, factor_id, cnt, rn
          from (
            select app_sid, std_factor_id, factor_id,
                COUNT(*) OVER (PARTITION BY app_sid, std_factor_id) cnt,
                ROW_NUMBER() OVER (PARTITION BY app_sid, std_factor_id ORDER BY factor_Id) rn
              from csr.factor  
             where std_factor_id is not null
         )
         where rn > 1
     )
);

CREATE UNIQUE INDEX CSR.UK_FACTOR_2 ON CSR.FACTOR (APP_SID, NVL(STD_FACTOR_ID, -FACTOR_ID));
/*
-- XXX: barfing on live but I think it's sane
ALTER TABLE CSR.FACTOR ADD CONSTRAINT CK_FACTOR_REG CHECK (
	(REGION_SID IS NULL AND STD_FACTOR_ID IS NOT NULL) 
	OR (REGION_SID IS NOT NULL AND STD_FACTOR_ID IS NULL)
);
*/

-- wasn't previously populated.
ALTER TABLE csr.FACTOR_HISTORY DROP COLUMN CHANGED_DTM;
ALTER TABLE csr.FACTOR_HISTORY ADD (CHANGED_DTM DATE DEFAULT SYSDATE NOT NULL);

@..\factor_pkg

@..\csr_user_body
@..\factor_body

@update_tail
