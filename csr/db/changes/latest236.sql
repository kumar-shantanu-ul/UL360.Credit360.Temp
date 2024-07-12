-- Please update version.sql too -- this keeps clean builds in sync
define version=236
@update_header

DECLARE
    v_cnt NUMBER(10);
BEGIN
    --this was missing on live but is on "clean builds", e.g. DT
    SELECT COUNT(*) INTO v_cnt FROM user_constraints WHERE constraint_name IN ('REFCUSTOMER967', 'FK_REGION_APP');    
    IF v_cnt = 0 THEN
       EXECUTE IMMEDIATE 'alter table region add constraint RefCUSTOMER967 foreign key (app_sid) references customer(app_sid)';
    END IF;
END;
/

DECLARE
    v_cnt NUMBER(10);
BEGIN
    --this was missing on live but is on "clean builds", e.g. DT
    SELECT COUNT(*) INTO v_cnt FROM user_constraints WHERE constraint_name='FK_IND_APP_CUST_APP';    
    IF v_cnt = 0 THEN
       EXECUTE IMMEDIATE 'alter table ind add constraint FK_IND_APP_CUST_APP foreign key (app_sid) references customer(app_sid)';
    END IF;
END;
/

@update_tail
