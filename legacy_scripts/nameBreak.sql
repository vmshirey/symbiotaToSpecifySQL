DROP PROCEDURE IF EXISTS agent_reclamation;
DROP PROCEDURE IF EXISTS procIteration;
DELIMITER //

CREATE PROCEDURE procIteration ()
BEGIN
DECLARE done BOOLEAN DEFAULT FALSE;
DECLARE verbatimNameHandler varchar(170);
DECLARE cur CURSOR FOR SELECT VerbatimName FROM tempAgent WHERE VerbatimName LIKE '%,%';
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

OPEN cur;

testLoop: LOOP
	FETCH cur INTO verbatimNameHandler;
	IF done THEN 
		LEAVE testLoop;
	END IF;
	CALL agent_reclamation(verbatimNameHandler);
END LOOP testLoop;

CLOSE cur;
END //

CREATE PROCEDURE agent_reclamation (IN VerbatimName VARCHAR(170)) 
BEGIN
DECLARE verbatimNameHandler varchar(170);
DECLARE tempAgentName varchar(170); 
SET verbatimNameHandler = VerbatimName;
	WHILE LENGTH(verbatimNameHandler) > 0 DO -- while there's more stuff left
		IF LOCATE(',', verbatimNameHandler) > 0 THEN -- and theres a comma to be found
			SET tempAgentName = SUBSTRING(verbatimNameHandler,1,LOCATE(',',verbatimNameHandler) - 1); -- set the temp variable to everything from the first character to the first comma
		ELSE
			SET tempAgentName = verbatimNameHandler; -- set the name if there are no commas
			SET verbatimNameHandler = ''; -- won't accept procedure without update --
		END IF;
		-- INSERT INTO agentReclamation SET tempAgentName = tempAgentName;
		INSERT INTO agentReclamation(tempAgentName) VALUES (tempAgentName);  -- insert the new names into the agentReclamation table
		SET verbatimNameHandler = REPLACE(verbatimNameHandler, CONCAT(tempAgentName, ','), ''); -- won't accept procedure without update --
	END WHILE;
END //

DELIMITER ;

CALL procIteration();
-- CALL agent_reclamation('V. Shirey');
-- CALL agent_reclamation('V. Shirey, J. Smith, W. Young');

