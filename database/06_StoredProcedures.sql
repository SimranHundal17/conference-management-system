USE conference_management_system;

-- ==========================================
-- Procedure 1: Register Student for Event
-- ==========================================

DROP PROCEDURE IF EXISTS RegisterStudentForEvent;

DELIMITER $$

CREATE PROCEDURE RegisterStudentForEvent(
    IN p_student_id INT,
    IN p_event_id INT
)
BEGIN

    INSERT INTO registration(
        student_id,
        event_id,
        status_id
    )
    VALUES(
        p_student_id,
        p_event_id,
        1
    );

END$$

DELIMITER ;


-- ==========================================
-- Procedure 2: Generate Certificate
-- ==========================================

DROP PROCEDURE IF EXISTS GenerateCertificate;

DELIMITER $$

CREATE PROCEDURE GenerateCertificate(
    IN p_registration_id INT,
    IN p_template_id INT
)
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM registration r
        JOIN event e
            ON r.event_id = e.event_id
        WHERE r.registration_id = p_registration_id
          AND e.end_date < CURDATE()
    )
    THEN

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Certificate can be generated only after the event has ended';

    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM certificate
        WHERE registration_id = p_registration_id
    )
    THEN

        INSERT INTO certificate(
            registration_id,
            template_id,
            certificate_code,
            issued_date
        )
        VALUES(
            p_registration_id,
            p_template_id,
            CONCAT('CERT-', p_registration_id),
            CURDATE()
        );

    END IF;

END$$

DELIMITER ;

SELECT *
FROM registration
ORDER BY registration_id DESC;

CALL RegisterStudentForEvent(3,1);

SELECT *
FROM registration
ORDER BY registration_id DESC;

CALL GenerateCertificate(1,1);

SELECT *
FROM certificate;

SHOW PROCEDURE STATUS
WHERE Db = 'conference_management_system';
