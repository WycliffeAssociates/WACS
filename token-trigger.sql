DELIMITER //

USE `gitea`//

IF NOT EXISTS (
    SELECT *
    FROM information_schema.triggers
    WHERE trigger_schema = DATABASE()
    AND trigger_name = 'before_insert_access_token'
) THEN


    CREATE TRIGGER before_insert_access_token
    BEFORE INSERT ON access_token
    FOR EACH ROW
    BEGIN
        IF NEW.scope IS NULL OR NEW.scope = '' THEN
            SET NEW.scope = 'write:repository,write:user';
        END IF;
    END//
END IF//

DELIMITER ;

