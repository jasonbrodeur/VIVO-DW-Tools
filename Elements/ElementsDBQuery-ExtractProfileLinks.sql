SELECT		[Last Name],
			[First Name],
			STUFF([Initials], 1, 1, '') AS [Middle Initials],
			[Proprietary ID],
			[Username],
			[ID] AS [Elements ID],
			CONCAT('https://expertsmanager.mcmaster.ca/userprofile.html?uid=',[ID],'&em=true') AS [Link to profile]
FROM		[User]
WHERE		ID > 1				-- exclude anonymous and system users
AND			[Is Academic] = 1	-- exclude non-academic users
ORDER BY	[Last Name], [First Name], [Initials]
;