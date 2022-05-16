# Timeout-for-TSQL-agenten-jobs

The function starts the actual SQL agent job and monitors the specified maximum runtime.
If the timeout has been exceeded, the relevant job is stopped and an email is sent.

Installation:

Only a second TSQL agent job is required, which then monitors the other job in the specified time window.

Die Funktion startet den eigentlichen SQL Agentenjob und überwacht die angegebene maximale Laufzeit.
Wenn das Timeout überschritten wurde, wird der betreffende Job gestoppt und eine E-Mail versendet.

Installation:

Es wird lediglich ein zweiter TSQL Agenten Job benötigt, der dann in den angegebenen Zeitfenstern den anderen Job überwacht.
