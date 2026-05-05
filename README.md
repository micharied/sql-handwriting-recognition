# SQL is a Programming Language: Handwriting Recognition

Dieses Repo entsteht im Rahmen des Seminars: SQL is a Programming Language (https://db.cs.uni-tuebingen.de/teaching/ss26/sql-is-a-programming-language/).
Ziel ist es eine Handwriting Recognition nach folgendem Beispiel (https://jackschaedler.github.io/handwriting-recognition/) in SQL/DuckDB zu implementieren.

## Projekt Struktur

### sql
Hier ist für jeden "Pipeline"-Schritt eine Datei um mit Beispiel-Werten direkt die Queries zu testen.

Zusätzlich gibt es mit `sql/00_final_pipeline.sql` einen gemeinsamen Einstiegspunkt, der alle Phasen in einem `WITH RECURSIVE`-Block als explizite Zwischen-CTEs verbindet.

### macros
Hier liegen die "puren" Queries, welche von sql/ und demo-app/ genutzt werden.

Die Makros sind für isolierte Phasen-Experimente gedacht. Die komplette End-to-End Pipeline bleibt in einer Datei kompakt und direkt lesbar.

### demo-app
Hier soll eine simple HTML/JS App entstehen, welche ein Canvas direkt mit der DuckDB JS API an die Queries anbindet.

## Entwicklung
Für die Entwicklung ist `nodejs` und `duckdb` notwendig. Das Projekt stellt über Nix eine Entwicklungs-Shell mit allen relevanten Tools bereit.