define version=75
@update_header

UPDATE CHAIN.ALL_COMPONENT_TYPE
SET    
       DESCRIPTION          = 'Purchased Part'
WHERE  COMPONENT_TYPE_ID    = 3;

UPDATE CHAIN.ALL_COMPONENT_TYPE
SET    
       DESCRIPTION          = 'Wood Product Input'
WHERE  COMPONENT_TYPE_ID    = 50;



@update_tail