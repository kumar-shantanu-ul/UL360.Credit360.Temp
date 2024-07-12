-- Please update version too -- this keeps clean builds in sync
define version=1726
@update_header

-- legacy supplier bug - wasn't enforcing unique index - meant user could be linked to more than one company - not true for SUPPLIER (is true for CHAIN)

-- clear out any existing dups - all credit/npsl people on live
DECLARE
    v_comp_name supplier.company.name%TYPE;
    v_user_name csr.csr_user.full_name%TYPE;
BEGIN 
    
    -- get the affected apps 
    FOR r IN (
        select host from csr.customer where app_sid in (
            SELECT app_sid FROM (
            SELECT app_sid, csr_user_sid, count(*) cnt 
              FROM supplier.company_user
              group by app_sid, csr_user_sid
            )
            where cnt>1
        )
    )LOOP
    
        security.user_pkg.logonadmin(r.host);
    
        FOR u IN (
            select csr_user_sid,company_sid  
            from supplier.company_user 
            where csr_user_sid IN
            (
                SELECT csr_user_sid FROM (
                SELECT csr_user_sid, count(*) cnt 
                  FROM supplier.company_user
                  group by app_sid, csr_user_sid
                )
                where cnt>1
            ) 
            and app_sid = security.security_pkg.getapp
            order  by csr_user_sid,company_sid  
        ) LOOP
        
            SELECT name INTO v_comp_name FROM supplier.company WHERE company_sid = u.company_sid and app_sid = security.security_pkg.getapp;
            
            SELECT full_name INTO v_user_name FROM csr.csr_user WHERE csr_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp;
            
           --DBMS_OUTPUT.PUT_LINE('Removing user '|| v_user_name ||' from '|| v_comp_name || ' for ' || r.host);
          
           -- clearing any dead chaininfo stuff 
           delete from supplier.invite_questionnaire where invite_id IN (
                select invite_id FROM supplier.invite where sent_by_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp
           );
           delete from supplier.invite where sent_by_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp;
           
           delete from supplier.message_contact where contact_id IN (
                select contact_id from supplier.contact where registered_as_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp
           );
           delete from supplier.contact where registered_as_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp;
           
           delete from supplier.questionnaire_request where supplier_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp;
           delete from supplier.questionnaire_request where procurer_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp;
           delete from supplier.questionnaire_request where released_by_user_sid = u.csr_user_sid and app_sid = security.security_pkg.getapp;
           

           
           -- removing contact from company 
           supplier.company_pkg.RemoveContact(security.security_pkg.GetAct, security.security_pkg.getapp, u.company_sid, u.csr_user_sid);
        
        END LOOP;
        
    END LOOP;

END;
/

DROP INDEX supplier.IX_COMPANY_USER_CSR_USER_SID;

CREATE UNIQUE INDEX supplier.UK_CSR_USER_SID ON supplier.COMPANY_USER
(APP_SID, CSR_USER_SID);

@update_tail