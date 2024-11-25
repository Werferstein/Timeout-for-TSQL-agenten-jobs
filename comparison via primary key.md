__*Gebrauchsanleitung für den SQL-Code zum Vergleichen von Tabellen*__

Zweck des Skripts
Dieses SQL-Skript dient zum Vergleichen zweier Tabellen (eine Quelle und eine Ziel-Tabelle) aus verschiedenen Datenbanken und zeigt etwaige Unterschiede in den Daten an.
Der Vergleich erfolgt basierend auf den Primärschlüsseln und bietet die Möglichkeit, bestimmte Felder von der Vergleichsanalyse auszuschließen (z. B. Audit- oder Systemfelder).

Hauptfunktionen des Skripts:

    • Vergleich der Zeilen und Felder zweier Tabellen basierend auf den Primärschlüsseln.    
    • Möglichkeit, Felder von der Vergleichsanalyse auszuschließen (über eine Blacklist).    
    • Darstellung der Anzahl der Unterschiede in Feldern und Zeilen.    
    • Ausgabe von detaillierten Zeilenunterschieden (optional) basierend auf den Primärschlüsseln.    
    • Option, die Anzahl der verglichenen Zeilen zu begrenzen.
    
Vorbereitung und Konfiguration

__* 1. Eingabeparameter:*__

Bevor das Skript ausgeführt wird, müssen die folgenden Eingabewerte definiert werden:

@ProcessId 					Eine eindeutige Prozess-ID, die in den Ausgabedaten verwendet wird.

@tableName 					Der Name der Tabelle, die verglichen werden soll.

@DatabaseName				Der Name der Quell-Datenbank, in der sich die Tabelle befindet.

@DatabaseSchema			Das Schema der Quelltabelle (normalerweise 'dbo', es sei denn, es wird etwas anderes verwendet).

@FieldNameBlackList	Eine durch Kommas getrennte Liste von Spaltennamen, die vom Vergleich ausgeschlossen werden sollen.

@ServerLink					Der Name des verknüpften Servers (optional, falls die Ziel-Datenbank auf einem anderen Server liegt). '' (leer, wenn nicht erforderlich)

@TargetDatabaseName Der Name der Ziel-Datenbank, mit der die Quell-Datenbank verglichen werden soll.

@ifDiff_TOP					Eine Begrenzung der Anzahl der Zeilen, die bei der Anzeige von Unterschieden zurückgegeben werden.		'TOP (1000)'

2. Erläuterung der Parameter:
3. 
    • @ProcessId: Wird in allen Ausgaben verwendet, um den Prozess eindeutig zu kennzeichnen. Es ist hilfreich, um mehrere Vergleiche zu unterscheiden.
   
    • @tableName: Der Name der zu vergleichenden Tabelle. Achten Sie darauf, dass der Tabellenname in beiden Datenbanken vorhanden ist.
   
    • @DatabaseName und @TargetDatabaseName: Die Datenbanken, die verglichen werden. Dies können unterschiedliche Datenbanken auf dem gleichen oder verschiedenen Servern sein.
   
    • @FieldNameBlackList: Falls bestimmte Felder von der Analyse ausgeschlossen werden sollen (z. B. auditbezogene Felder wie CreatedDate),
      können diese Felder hier aufgeführt werden. Diese Felder werden beim Vergleich ignoriert.
   
    • @ServerLink: Nur erforderlich, wenn die Ziel-Datenbank auf einem anderen Server liegt. Der Server-Link stellt die Verbindung zur Ziel-Datenbank her.
   
    • @TargetDatabaseName: Name der Ziel-Datenbank, die die zu vergleichende Tabelle enthält.
   
    • @ifDiff_TOP: Dies ist optional und ermöglicht es, die Anzahl der Zeilen in den Ausgabedaten zu begrenzen, um die Leistung zu optimieren.

Ablauf des Skripts:
__*1. Verbindung zu den Tabellen herstellen*__

    • Das Skript überprüft, ob die Quell- und Zieltabellen existieren. Wenn eine der Tabellen nicht vorhanden ist,
      wird der Vergleich nicht ausgeführt, und eine Fehlermeldung wird angezeigt.
__*2. Primärschlüssel ermitteln*__

    • Es wird die Tabelle ##TempTablePkList erstellt, die die Primärschlüssel der Quell-Tabelle enthält. Diese werden verwendet,
      um Zeilen zwischen den Tabellen zu verknüpfen.
      Wenn keine Primärschlüssel gefunden werden, wird das Skript gestoppt, da der Vergleich auf einem Primärschlüssel basiert.
__*3. Spaltennamen extrahieren*__

    • Das Skript verwendet sys.dm_exec_describe_first_result_set, um die Spaltennamen und deren Metadaten aus der Quell-Tabelle zu extrahieren.
      Es filtert timestamp-Spalten und beachtet die Blacklist.
      Diese Informationen werden in der temporären Tabelle ##TempTablecolumn_names gespeichert.
__*4. Vergleich der Tabellen*__

    • Das Skript vergleicht die Zeilen der Quell- und Ziel-Tabelle auf Basis der Primärschlüssel.
      Es prüft, ob die Werte der Spalten unterschiedlich sind und zählt diese Unterschiede.
      Unterschiede in Feldern (FieldDiff) und Zeilen (CountDiff) werden gezählt.
__*5. Ergebnisse der Unterschiede*__

    • Es wird eine Zusammenfassung der Unterschiede ausgegeben, die Folgendes umfasst:
        ◦ Anzahl der unterschiedlichen Felder (Daten in den Spalten sind verschieden).
          Anzahl der unterschiedlichen Zeilen (Unterschiedliche Anzahl an Zeilen zwischen Quell- und Ziel-Tabelle).
          Anzahl der unterschiedlichen Primärschlüssel (Zeilen mit gleichen Primärschlüsseln, aber unterschiedlichen Werten in den Spalten).
          Optional werden die genauen Zeilen mit den Unterschieden angezeigt, wenn @ifDiff_TOP gesetzt ist.
__*6. Bereinigung*__

    • Am Ende des Skripts werden alle temporären Tabellen 
      (##TempTablePkList, ##TempTablecolumn_names, ##columnBlacklist) gelöscht,
      um die temporären Ressourcen freizugeben.


Ingolf Hill, werferstein.org 11/2024
