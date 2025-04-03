# Engine Development Roadmap

### 1. Core Systems & Infrastructure

1. Implement die Kernsysteme, den Entry Point und die Applikationsschicht. Starte das erste Fenster.

2. Entwickle grundlegende Datenstrukturen wie dynamische Arrays und Strings.

3. Plane das Speicher- und Thread-Subsystem.

4. Implementiere eine Rendering-Oberfläche, um Nuklear UI funktional zu machen und Debug-Interfaces in C zu ermöglichen.

5. Erstelle eine Test-Pipeline für unterstützte Plattformen auf CI.

6. Entwickle eine Mathe-Bibliothek mit Vektoren und Matrizenmultiplikation.

### 2. Erste Visualisierung & Physik

1. Implementiere das erste einfache 3D-Rendering eines Würfels (mit Wiederverwendbarkeit zur Testung des Dart-Interaktionsmoduls).

2. Review und Refactoring der bisherigen Schritte.

3. Entwickle das Physikmodul.

4. Kombiniere Renderer und Physikmodul, um erste Impulse sichtbar zu machen.

5. Definiere eine konsistente Repräsentation des 3D-Raums im Code.

6. Implementiere 3D-Spatial-Sound.

7. Optimiere die Module für Multithreading und Performance.

### 3. Dart Interaktionsschicht (DEIL) & Erweiterbarkeit

1. Implementiere die Dart-Interaktionsschicht (DEIL) als eigenes Subsystem mit einer asynchronen Queue für Rendering, Audio, Netzwerk und native Calls.

2. Review und weiteres Refactoring.

3. Teste die Erweiterbarkeit der Dart-Interaktion durch Weiterentwicklung des Renderers.

4. Implementiere einen Asset-Manager und dessen Integration in DEIL.

5. Implementiere Shader-Support mit einem Loader und entsprechender Infrastruktur.

6. Erstelle eine API für DEIL, um Shadersysteme zu nutzen.

7. Optimiere DEIL und seine Verbindungen zur Engine.

8. Refactoring zur Stabilisierung der aktuellen Fortschritte.

10. Baue eine stabile C-Schnittstelle.

### 4. Erweiterte Rendering-Techniken

1. Implementiere fortgeschrittene Rendering-Techniken:

2. Ambient Occlusion

3. Screen Space Reflections

4. Global Illumination

5. LOD-Management und Übergänge

6. Materialsysteme

7. Post-Processing (erweiterbar über DEIL)

8. Implementiere Wassershaders und 2D-Rendering auf Planes.

9.  in Dart ein State Machine System sowie Flipbooks und 2D-Animationen.

10. Implementiere Konfigurationsoptionen für die Renderpipeline zur Anpassung der Performance für Low-End-Geräte.

### 5. UI & Debugging

1. Implementiere eine UI-Abstraktion für DEIL und ein dediziertes UI-Thread-Modul.

2. Entwickle ein 3D-Skelettsystem zur Befestigung von Meshes und Entitäten.

3. Implementiere eine optimierte Mathe-Bibliothek in Dart (mit Unboxed Variablen).

4. Weiteres Refactoring.

5. Integriere Debugging-Tools zur Performance-Analyse der Frame-Times.

6. Optimiere die Frame-Times.

### 6. Finalisierung & Erweiterungen

1. Implementiere Materialeigenschaften für Reflexion, Roughness, Texturen, Height Maps für Beleuchtung und Tessellation.

2. Stelle Post-Processing über DEIL zur Verfügung.

3. Implementiere Multi-Window-Support.

4.  der Plattformunterstützung.

5. Performance- und Stabilitätsoptimierung.

6. Erweitere die State Machine für allgemeine Nutzungsszenarien.

7. Implementiere KI-Algorithmen wie Pfadfindung und Sichtfeldberechnungen.

8. Portiere KI-Features auf DEIL.

9. Letztes großes Refactoring.

# Runner Development Roadmap

### 1. Basisfunktionen

1. Implementiere den Builder für C-Kompilierung und Dart-Cross-Kompilation.

2. Ermögliche Hot-Reloading von C-Code durch Austausch der Shared Library zur Laufzeit.

3. Entwickle den Projekt-Analyzer zur Extraktion von Projektinformationen für den Builder, Debugging und UI-Darstellung.

4. Implementiere einen internen HTTP-Server zur Bereitstellung von Projektinformationen und Steuerung von Abläufen.

5. Entwickle einen modularen Toolchain-Support für:

6. Dart-Toolchain-Integration

7. C-Paketmanager

8. VCS-Manager

9. Versions- und Abhängigkeitsverwaltung

10. Debugging-Management

11. HTTP-Backend-Management

13. Sprachserialisierung und Parsing

14. Refactoring der Struktur und Code-Qualität.

15. Implementiere einen zweiten HTTP-Server mit statischem Port für das Hosting des Editors als Web-App.

# Editor Tooling Roadmap

### 1. Grundlegende Infrastruktur

1. Importiere Widgets aus alten Projekten.

2. Initiales Refactoring der Struktur.

### 2. Implementierung

1. Entwickle eine zentrale Startklasse, die HTTP-Port und Projektpfade per Kommandozeile erhält.

2. Integriere eine API zur Kommunikation mit dem Projektserver für Widget-Daten und Tools.

3. Implementiere eine persistente Speicherung des Widget-States über den Webhost-Server.

4. Trenne Business-Logik von UI-Interaktionen:

5. Animation und Reaktionen im Web-Client

6. Applikationsstatus im Webhost-Backend

### 3. Weiterentwicklung

* Weitere Planung und Iteration in Abhängigkeit vom Entwicklungsstand des Runners.