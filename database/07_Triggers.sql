USE conference_management_system;

DROP TRIGGER IF EXISTS trg_registration_date;

DELIMITER $$

CREATE TRIGGER trg_registration_date
BEFORE INSERT ON registration
FOR EACH ROW
BEGIN

    IF NEW.registration_date IS NULL THEN
        SET NEW.registration_date = NOW();
    END IF;

END$$

DELIMITER ;

SHOW TRIGGERS
FROM conference_management_system;