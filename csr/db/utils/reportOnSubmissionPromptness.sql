----------------------------------------------------------------------------------------------
-- this gets a report (done for ICA) on how many sheets are 
-- Open and now late
-- Open and not yet late
-- Submited or greater and were overdue when submitted
-- Submited or greater and were not overdue when submitted
--
-- Submited or greater =  not in state waiting (0) or rejected (2) (asme logic used for sending overdue reminders)
-- Open = in state waiting (0) or rejected (2) 
----------------------------------------------------------------------------------------------

SELECT  mnth, status,  count(*)  FROM
(
    SELECT TRUNC(mxdtm, 'MONTH') mnth, 
    CASE
        WHEN SHEET_ACTN = 'O' AND overdue = 0 then 'Open and not yet overdue'
        WHEN SHEET_ACTN = 'O' AND overdue = 1 then 'Open and now overdue'
        WHEN SHEET_ACTN = 'S' AND overdue = 0 then 'Submitted on or before time'
        WHEN SHEET_ACTN = 'S' AND overdue = 1 then 'Submitted past submission deadline'
        ELSE 'unknown'
    END status
    FROM 
    (
        SELECT sheet_id, sheet_actn, overdue, mxdtm,
        LEAD(SHEET_ID, 1, -1) OVER (PARTITION BY sheet_id ORDER BY sheet_id, mxdtm) PREV_sheet
        FROM
        (
            SELECT sheet_id, sheet_actn, overdue, max(action_dtm) mxdtm FROM (
                        select sheet_id, action_dtm, sheet_actn, overdue, 
                            LAG(SHEET_ACTN, 1, 'F') OVER (PARTITION BY sheet_id ORDER BY sheet_id, action_dtm) PREV_ACTN -- return F if first row of partition
                        from
                        (
                            select  s.sheet_id, s.DELEGATION_SID, s.START_DTM, s.END_DTM, s.REMINDER_DTM, 
                            s.SUBMISSION_DTM, 
                            --s.end_dtm + 60 SUBMISSION_DTM, 
                            sh.ACTION_DTM,
                            CASE
                                WHEN sh.SHEET_ACTION_ID IN (0,2) THEN 'O'
                                ELSE 'S'
                            END SHEET_ACTN,
                            CASE
                                WHEN SYSDATE > submission_dtm AND SH.SHEET_ACTION_ID IN (0,2) THEN 1 -- late 
                                WHEN SYSDATE <= submission_dtm AND SH.SHEET_ACTION_ID IN (0,2) THEN 0 -- not late 
                                WHEN action_dtm > submission_dtm AND SH.SHEET_ACTION_ID NOT IN (0,2) THEN 1 -- late 
                                WHEN action_dtm <= submission_dtm AND SH.SHEET_ACTION_ID NOT IN (0,2) THEN 0 -- not late
                                /*WHEN SYSDATE > s.end_dtm + 60 AND SH.SHEET_ACTION_ID IN (0,2) THEN 1 -- late 
                                WHEN SYSDATE <= s.end_dtm + 60 AND SH.SHEET_ACTION_ID IN (0,2) THEN 0 -- not late 
                                WHEN action_dtm > s.end_dtm + 60 AND SH.SHEET_ACTION_ID NOT IN (0,2) THEN 1 -- late 
                                WHEN action_dtm <= s.end_dtm + 60 AND SH.SHEET_ACTION_ID NOT IN (0,2) THEN 0 -- not late*/
                                ELSE -1
                            END overdue 
                            from sheet s, delegation d, sheet_history sh
                                where s.DELEGATION_SID = d.DELEGATION_SID
                                and s.START_DTM >= '1 sep 2007'
                                and s.SHEET_ID = sh.SHEET_ID
                                and d.app_sid = (select app_sid from customer where host = 'ica.credit360.com')
                                --and s.sheet_id in (89705, 71940)
                           order by sheet_id, action_dtm
                       )
                       order by sheet_id, action_dtm
            ) WHERE sheet_actn != PREV_ACTN
            group by sheet_id, sheet_actn, overdue
            order by sheet_id, sheet_actn, overdue
        )
        order by sheet_id
    )
    where sheet_id != prev_sheet
)
group by mnth, status
order by mnth, status
        
----------------------------------------------------------------------------------------------
-- simple (lazy) breakdown and count of days between sheet end date and submission date
----------------------------------------------------------------------------------------------

    -- breakdown of grace period
    select grace_period, count(*) cnt FROM 
    (
    select s.sheet_id, s.DELEGATION_SID, s.START_DTM, s.END_DTM, s.SUBMISSION_DTM, s.REMINDER_DTM, s.SUBMISSION_DTM - s.end_dtm grace_period
    from sheet s, delegation d
        where s.DELEGATION_SID = d.DELEGATION_SID
        and s.START_DTM >= '1 sep 2007'
        and d.app_sid = (select app_sid from customer where host = 'ica.credit360.com')
        --and s.sheet_id in (79800, 79802)
    )group by grace_period
    order by grace_period
    
    
    



