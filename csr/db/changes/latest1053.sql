-- Please update version.sql too -- this keeps clean builds in sync
define version=1053
@update_header

grant insert,select,update,delete on csrimp.factor to web_user;
grant insert,select,update,delete on csrimp.deleg_ind_deleg_ind_group to web_user;
grant insert,select,update,delete on csrimp.deleg_ind_group to web_user;
grant insert,select,update,delete on csrimp.deleg_ind_form_expr to web_user;
grant insert,select,update,delete on csrimp.form_expr to web_user;

alter table csrimp.ind drop CONSTRAINT CK_IND_TYPE;
alter table csrimp.ind add CONSTRAINT CK_IND_TYPE CHECK (IND_TYPE IN (0,1,2,3));

-- rename inconsistently named FKs
ALTER TABLE CSR.FORM_EXPR RENAME CONSTRAINT FORM_EXPR_DELEG TO FK_DELEGATION_FORM_EXPR;
ALTER TABLE CSR.DELEG_IND_FORM_EXPR RENAME CONSTRAINT DELEG_IND_FRM_EXP_DEL_IND TO FK_DLG_IND_DLG_IND_FRM_EXPR;
ALTER TABLE CSR.DELEG_IND_FORM_EXPR RENAME CONSTRAINT DELEG_IND_FRM_EXP_FRM_EXP TO FK_FRM_XPR_DLG_IND_FRM_XPR;
ALTER TABLE CSR.DELEG_IND_GROUP RENAME CONSTRAINT DELEGINDGROUP_DELEG TO FK_DLG_DLG_IND_GRP;
ALTER TABLE CSR.DELEG_IND_DELEG_IND_GROUP RENAME CONSTRAINT DELINDGRPDELIND_DELIND TO FK_DLG_IND_DG_ID_DG_ID_GR;

DECLARE
	v_cnt	number(10);
BEGIN
	-- there was a problem with latest1049 where this didn't get created due to a missing ; which somehow didn't break the tests
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM sys.all_constraints
	 WHERE owner = 'CSR'
	   AND constraint_name = 'DELINDGRPDELIND_DELINDGRP';
	DBMS_OUTPUT.PUT_LINE(v_cnt||' found');
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEG_IND_DELEG_IND_GROUP ADD (CONSTRAINT FK_DL_IN_GR_DIDIG FOREIGN KEY (APP_SID, DELEGATION_SID, DELEG_IND_GROUP_ID) REFERENCES CSR.DELEG_IND_GROUP (APP_SID,DELEGATION_SID,DELEG_IND_GROUP_ID) ON DELETE CASCADE ENABLE VALIDATE)';
	ELSE
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.DELEG_IND_DELEG_IND_GROUP RENAME CONSTRAINT DELINDGRPDELIND_DELINDGRP TO FK_DL_IN_GR_DIDIG';
	END IF;
END;
/

-- change table name to something more understandable
ALTER TABLE CSR.DELEG_IND_DELEG_IND_GROUP RENAME TO DELEG_IND_GROUP_MEMBER;
ALTER TABLE CSRIMP.DELEG_IND_DELEG_IND_GROUP RENAME TO DELEG_IND_GROUP_MEMBER;

-- and inconsistently named primary keys too
ALTER TABLE CSR.FORM_EXPR RENAME CONSTRAINT FORM_EXPR_PK TO PK_FORM_EXPR;
ALTER TABLE CSR.DELEG_IND_GROUP RENAME CONSTRAINT DELEG_IND_GROUP_PK TO PK_DELEG_IND_GROUP;
ALTER TABLE CSR.DELEG_IND_FORM_EXPR RENAME CONSTRAINT DELEG_IND_FORM_EXPR_PK TO PK_DELEG_IND_FORM_EXPR;
ALTER TABLE CSR.DELEG_IND_GROUP_MEMBER RENAME CONSTRAINT DEL_IND_DEL_IND_GROUP_PK TO PK_DELEG_IND_GROUP_MEMBER;

-- this was breaking csrimp and seems a sesnsible constraint to have added (i.e. name must be unique for a conversion)
begin    
    -- make sure measure_conversions are uniquely named
    -- the fixing up focuses on sheet + val -- there weren't many instances on live and they were all in these
    -- tables but of course it's possibly locally that things might be different. It does sort by most common
    -- instance so fingers crossed! The delete stmt will just fail if this happens and it'll be easy enough
    -- to add in another update row.
    security.user_pkg.logonadmin;
    for r in (
        select z.*,
            row_number() over (partition by measure_sid, lower(description) order by used desc) rn,
            first_value(measure_conversion_id) over (partition by measure_sid, lower(description) order by used desc) to_mcv_id
          from (
            select y.*, (select count(*) from csr.val where entry_measure_conversion_id = y.measure_conversiON_id and app_sid = y.app_sid) used
              from (
                select *
                  from (
                    select measure_conversion_id, measure_sid, description, c.app_sid, host,
                        count(measure_conversion_id) over (partition by measure_sid, lower(description)) cnt
                      from csr.measure_conversion mc
                        join csr.customer c on mc.app_sid = c.app_sid
                )x
                where cnt > 1
            )y
        )z
    )
    loop
        if r.rn > 1 then
			dbms_output.put_line(r.host||': updating '||r.used||' instances of measure_conversion_id '||r.measure_conversion_id||' to '||r.to_mcv_id);
            update csr.sheet_value set entry_measure_conversion_id = r.to_mcv_id where app_sid = r.app_sid and entry_measure_conversion_id = r.measure_conversion_id;
            update csr.sheet_value_change set entry_measure_conversion_id = r.to_mcv_id where app_sid = r.app_sid and entry_measure_conversion_id = r.measure_conversion_id;
            update csr.val_change set entry_measure_conversion_id = r.to_mcv_id where app_sid = r.app_sid and entry_measure_conversion_id = r.measure_conversion_id;
            update csr.val set entry_measure_conversion_id = r.to_mcv_id where app_sid = r.app_sid and entry_measure_conversion_id = r.measure_conversion_id;
            delete from csr.measure_conversion_period where measure_conversion_id = r.measure_conversioN_id;
            delete from csr.measure_conversion where measure_conversion_id = r.measure_conversioN_id;
        end if;
    end loop;
end;
/

CREATE UNIQUE INDEX CSR.UK_MEASURE_CONV_NAME ON CSR.MEASURE_CONVERSION(APP_SID, MEASURE_SID, LOWER(DESCRIPTION));

@..\deleg_admin_pkg
@..\schema_pkg
@..\csrimp\imp_pkg

@..\deleg_admin_body
@..\delegation_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
