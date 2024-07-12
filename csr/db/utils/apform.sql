define old_feedback=&&feedback
define feedback=0
set feedback &&feedback

variable approval_step_id number
exec :approval_step_id := &1

select pending_ind_id, parent_ind_id, maps_to_ind_sid, element_type, level, description
from pending_ind
start with pending_ind_id in (select pending_ind_id from approval_step_ind where approval_step_id = :approval_step_id) and parent_ind_id is null
connect by parent_ind_id = prior pending_ind_id
order siblings by pos
;

define feedback=&&old_feedback
set feedback &&feedback