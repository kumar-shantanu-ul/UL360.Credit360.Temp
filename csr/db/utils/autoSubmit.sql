-- find first sheet_id that has been:
--  * merged with main  (leave) 9
--  * merged with main with mod (merge) 12
--  * approved (submit) 3,6
--  * submitted and not approved (approve) 1,11

-- failing that pick the bottom most sheet (submit or merge if at top)  0,10
DECLARE
	v_code NUMBER;
	v_errm VARCHAR2(64);
	v_cnt number(10) := 0;
	v_act				security_pkg.T_ACT_ID;
BEGIN
	user_pkg.logonadmin('imi.credit360.com');
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
    for r in (
        select *
          from (
            select root_sheet_id, sheet_id, last_action_id, score, lvl, 
                case when first_value(sheet_id) over (partition by root_sheet_id order by score asc) = sheet_id then 1 else 0 end process
              from (
                   SELECT d.app_sid, d.name, connect_by_root d.delegation_sid root_delegation_sid, d.delegation_sid, d.parent_sid,
                        level lvl, s.sheet_id, prior s.sheet_Id parent_sheet_id, s.start_dtm, s.end_dtm,
                        last_action_id, last_action_colour, connect_by_root sheet_id root_sheet_id,
                        case 
                            when last_action_id in (9,12) then 1 * level * 10
                            when last_action_id in (3,6) then 2000 -- we don't want to touch these (accepted)
                            when last_action_id in (1,11) then 3 * level * 10
                            when last_action_id in (0,10) then 1000 - (4 * level * 10)
                        end score
                      FROM delegation d 
                        JOIN sheet_with_last_action s on d.delegation_sid = s.delegation_sid  AND d.app_sid = s.app_sid
                      WHERE d.start_dtm = '1 jan 2010' and name like 'RB Audit%'
                      START WITH d.parent_sid = d.app_sid
                    CONNECT BY PRIOR d.delegation_sid = d.parent_sid
                        AND PRIOR s.end_dtm > s.start_dtm
                        AND PRIOR s.start_dtm < s.end_dtm              
              )s
          )
          where process = 1
            and last_action_id in (1,11,0,10, 12) -- exclude anything in 9 (merged) + (3,6)
    )
    loop
        begin
            IF r.lvl = 1 THEN
                sheet_pkg.MergeLowest(security_pkg.getact, r.sheet_id, 'Merged at request of Duggie Brooks', 0, 1);	
            ELSIF r.last_action_id IN (0, 10) THEN
                -- approved or at bottom of the pile so submit
                sheet_pkg.Submit(security_pkg.getact, r.sheet_id, 'Submitted at request of Duggie Brooks', 1);	
            ELSIF r.last_action_id IN (1,11) THEN
                -- submitted and not apporoved, so approve
                sheet_pkg.Accept(security_pkg.getact, r.sheet_id, 'Accepted at request of Duggie Brooks', 1);	
            ELSE
                dbms_output.put_line('unknown status on sheet id '||r.sheet_id);            
            END IF;
            v_cnt := v_cnt + 1;
        exception
            when others then
                v_code := SQLCODE;
				v_errm := SUBSTR(SQLERRM, 1 , 64);
				DBMS_OUTPUT.PUT_LINE('Failed on sheet id '||r.sheet_id||': ' || v_code || '- ' || v_errm);
        end;
    end loop;
    DBMS_OUTPUT.PUT_LINE('processed '||v_cnt);
end;
/