/*
SQL Job Timeout, Ingolf Hill 2022 Werferstein.org

The function starts the actual SQL agent job and monitors the specified maximum runtime.
If the timeout has been exceeded, the relevant job is stopped and an email is sent.

Die Funktion startet den eigentlichen SQL Agentenjob und überwacht die angegebene maximale Laufzeit.
Wenn das Timeout überschritten wurde, wird der betreffende Job gestoppt und eine E-Mail versendet.
*/


DECLARE 
@job_name NVARCHAR(MAX) = 'Agenten Job Name',
@TimeOutInMin INT		    = 60


------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @startTime DATETIME = GETDATE(), @runtime int = 0, @message varchar(MAX) = '', @cr VARCHAR(2) =CHAR(13)+ CHAR(10), @ERRORSTATE BIT = 0, @htmlStart VARCHAR(3) = '<P>',  @htmlStop VARCHAR(6) = '<br />'

SET @message = @htmlStart + '---------------------------------------------------------------------' + @htmlStop;


--test if running?
IF OBJECT_ID('tempdb.dbo.#RunningJobs') IS NOT NULL DROP TABLE #RunningJobs
CREATE TABLE #RunningJobs (Job_ID UNIQUEIDENTIFIER, Last_Run_Date INT, Last_Run_Time INT, Next_Run_Date INT, Next_Run_Time INT, Next_Run_Schedule_ID INT, Requested_To_Run INT, Request_Source INT, Request_Source_ID VARCHAR(100),  Running INT,  Current_Step INT,  Current_Retry_Attempt INT,  State INT )
INSERT INTO #RunningJobs EXEC master.dbo.xp_sqlagent_enum_jobs 1,garbage  

DECLARE @jobState SYSNAME ='';
SELECT    
  @jobState = name
FROM     #RunningJobs JSR 
LEFT JOIN  msdb.dbo.sysjobs ON JSR.Job_ID=sysjobs.job_id 
WHERE    Running=1 AND name = @job_name

if @jobState = '' 
BEGIN
	-- Start job
	SET @startTime = GETDATE();	
	EXEC msdb.dbo.sp_start_job @job_name = @job_name
	SET @message += @htmlStart + 'Start job ' + @job_name + ' at ' + CONVERT(varchar(20),@startTime) + @htmlStop
	WAITFOR DELAY '00:00:10';--wait for server commit
END
ELSE
	SET @message += @htmlStart + 'The job ' + @job_name + ' has already started!' + @htmlStop
------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------
-- Wait for Agent Job to finish
DECLARE @HistoryID AS INT = NULL, @start_execution_date DATETIME, @stopped BIT = 0
  WHILE @HistoryID IS NULL
  BEGIN
							
		--Read most recent Job History ID for the specified Agent Job name
        SELECT 
			TOP 1 
			@HistoryID = b.job_history_id,
			@start_execution_date = b.start_execution_date
		FROM msdb.dbo.sysjobs a
		INNER JOIN msdb.dbo.sysjobactivity b ON b.job_id = a.job_id
        WHERE a.name = @job_name
		ORDER BY b.start_execution_date DESC
        
		SET @runtime = DATEDIFF(Minute,@start_execution_date,GETDATE());			
		IF @runtime > @TimeOutInMin 
		BEGIN																								
			EXEC msdb.dbo.sp_stop_job @job_name;
			SET @message += @htmlStart + 'Timeout for job: ' + @job_name + ' after ' + convert(varchar(20),@runtime) + ' min.' + @htmlStop;
			SET @stopped = 1;
			SET @ERRORSTATE = 1;
			BREAK;			
		END
		--If Job is still running (Job History ID = NULL), wait 10 seconds
		WAITFOR DELAY '00:00:10';
    END--WHILE

if @stopped != 1
BEGIN
	TRUNCATE TABLE #RunningJobs;
	INSERT INTO #RunningJobs EXEC master.dbo.xp_sqlagent_enum_jobs 1,garbage  
	SELECT  @jobState = name FROM  #RunningJobs JSR LEFT JOIN  msdb.dbo.sysjobs ON JSR.Job_ID=sysjobs.job_id WHERE Running=1 AND name = @job_name
	IF @jobState != ''
	BEGIN	
		EXEC msdb.dbo.sp_stop_job @job_name;
		SET @runtime = DATEDIFF(Minute,@start_execution_date,GETDATE());
		SET @message += @htmlStart + 'Kill job: ' + @job_name + ' after ' + convert(varchar(20),@runtime) + ' min.' + @htmlStop;
		SET @ERRORSTATE = 1;
	END
END

-- Check Agent Job exit code to make sure it succeeded
IF (SELECT run_status FROM msdb.dbo.sysjobhistory WHERE instance_id = @HistoryID) != 1 
BEGIN
	SET @runtime = DATEDIFF(Minute,@start_execution_date,GETDATE());
	SET @message += @htmlStart + 'Child Agent Job failure: ' + @job_name + ' after ' + convert(varchar(20),@runtime) + ' min.' + @htmlStop;
	SET @ERRORSTATE = 1;
	RAISERROR (@message, 17, 1,'');
END


-- Check exit code
/*
SELECT history.run_status,*
FROM msdb.dbo.sysjobhistory AS history
WHERE history.instance_id = @HistoryID
*/

IF @ERRORSTATE = 1
BEGIN

	DECLARE @htmlText   	NVARCHAR(MAX) = '<P>ERROR! --> <br />' + @message
	DECLARE @Subject	VARCHAR (200) = 'Job status for: ' +  @job_name  + ' on ' + @@Servername 
	DECLARE @content	VARCHAR (MAX) = 'Job status for: ' +  @job_name  + ' on ' + @@Servername 
	DECLARE @HTML_Start 	VARCHAR (MAX) =
	N'
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
	<html lang="de">
	<head>
		<meta charset="UTF-8">
		<title>Job status for :' +  @job_name  + ' on ' + @@Servername + '</title>
		<meta name="description" content=' + @content + '>
	</head>
 
	<body>

	<h1>' + @content + '</h1>
	'
	DECLARE @HTML_End VARCHAR (MAX) =
	N'
	</body>
	</html>
	'

	SET @htmlText = @HTML_Start + @htmlText + @HTML_End
	EXEC msdb.dbo.sp_send_dbmail @recipients = @EmailAdresse1
			,@subject = @Subject
			,@body = @htmlText 
			,@profile_name = @EmailProfil
			,@body_format = 'HTML';		
END

Print @message
