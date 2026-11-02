# Verzeichnis von Verarbeitungstätigkeiten

Verzeichnis nach Art. 30 Abs. 1 DSGVO für die Website sudhaus-engen.de.

Dieses Verzeichnis wird nicht veröffentlicht. Es wird der Aufsichtsbehörde auf Anfrage vorgelegt (Art. 30 Abs. 4 DSGVO). Es nennt ausschließlich Kategorien, Empfänger und Fristen und enthält selbst keine personenbezogenen Daten.

Art. 30 Abs. 5 DSGVO nimmt Verantwortliche mit weniger als 250 Beschäftigten aus, soweit die Verarbeitung nur gelegentlich erfolgt. Die Website ist dauerhaft erreichbar und verarbeitet daher nicht nur gelegentlich. Das Verzeichnis wird deshalb geführt.

Die veröffentlichte [Datenschutzerklärung](../internal/web/templates/datenschutz.html) beschreibt dieselben Verarbeitungen. Änderungen an einem der beiden Texte sind im anderen nachzuziehen.

## Verantwortlicher

Joshua Moody, Lupfenstraße 1, 78234 Engen, Deutschland. E-Mail: joshua.moody.de@gmail.com.

Ein Datenschutzbeauftragter ist nicht bestellt. Die Voraussetzungen des Art. 37 Abs. 1 DSGVO und des § 38 Abs. 1 BDSG liegen nicht vor.

## Tätigkeit 1: Auslieferung der Website

| Angabe nach Art. 30 Abs. 1         | Inhalt                                                                                                                                                                                                                                                                              |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Zweck                              | Betrieb der Website und Beantwortung der Seitenabrufe                                                                                                                                                                                                                               |
| Rechtsgrundlage                    | Art. 6 Abs. 1 lit. f DSGVO. Berechtigtes Interesse: zuverlässige und sichere Auslieferung der Website                                                                                                                                                                               |
| Kategorien betroffener Personen    | Besucherinnen und Besucher der Website                                                                                                                                                                                                                                              |
| Kategorien personenbezogener Daten | IP-Adresse und die übrigen Verbindungsdaten der HTTP-Anfrage, verarbeitet allein zur Beantwortung der Anfrage                                                                                                                                                                       |
| Kategorien von Empfängern          | Microsoft als Hostingdienstleister, Auftragsverarbeiter nach Art. 28 DSGVO auf Grundlage des Microsoft Products and Services Data Protection Addendum (DPA), zugleich eigenständig Verantwortlicher für eigene Geschäftstätigkeiten nach demselben DPA                              |
| Drittlandübermittlung              | USA (Microsoft Corporation), gestützt auf den Angemessenheitsbeschluss zum EU-US Data Privacy Framework und auf die Standardvertragsklauseln nach Art. 46 Abs. 2 lit. c DSGVO, die Bestandteil des DPA sind                                                                         |
| Löschfristen                       | Die Anwendung speichert keine Anfragedaten. Die Betriebsprotokolle in Azure Log Analytics enthalten keine personenbezogenen Daten und werden nach 30 Tagen gelöscht. Die Speicherdauer der von Microsoft als eigenständig Verantwortlichem verarbeiteten Daten nennt das DPA nicht. |

## Tätigkeit 2: E-Mail-Korrespondenz

| Angabe nach Art. 30 Abs. 1         | Inhalt                                                                                                                        |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Zweck                              | Beantwortung von Anfragen an die im Impressum genannte E-Mail-Adresse                                                         |
| Rechtsgrundlage                    | Art. 6 Abs. 1 lit. f DSGVO, bei einem vertragsbezogenen Anliegen Art. 6 Abs. 1 lit. b DSGVO                                   |
| Kategorien betroffener Personen    | Absenderinnen und Absender von E-Mails                                                                                        |
| Kategorien personenbezogener Daten | E-Mail-Adresse, Name soweit angegeben, Inhalt der Nachricht und ihrer Anlagen                                                 |
| Kategorien von Empfängern          | Google Ireland Limited als Anbieter des Postfachs                                                                             |
| Drittlandübermittlung              | Keine vom Verantwortlichen veranlasste Übermittlung. Ob der Postfachanbieter in Drittländern verarbeitet, wurde nicht geprüft |
| Löschfristen                       | Löschung, sobald das Anliegen erledigt ist und keine gesetzliche Aufbewahrungspflicht entgegensteht                           |

## Technische und organisatorische Maßnahmen (Art. 30 Abs. 1 lit. g DSGVO)

- Alle Verbindungen zur Website laufen über TLS mit einem von Azure Container Apps verwalteten Zertifikat.
- Die Anwendung schreibt keine Anfragedaten in ein Protokoll. Die Regel steht in `.github/instructions/go.instructions.md` und in ADR 0001 und wird im Code-Review geprüft.
- Die Ingress-Tabelle `ContainerAppHTTPLogs`, die Client-IP-Adressen führt, wird nicht in den Log Analytics Workspace geschrieben.
- Der Log Analytics Workspace liegt in der Region Westeuropa und löscht nach 30 Tagen.
- Die Seite setzt keine Cookies, bindet kein Analyse- oder Tracking-Werkzeug ein und lädt keine Ressource von einem fremden Server.
- Die Azure-Umgebung wird ausschließlich vom Verantwortlichen verwaltet; die Infrastruktur ist in Terraform beschrieben und versioniert.

## Vorbehalt

Diese Einschätzung hat kein Anwalt geprüft. Die Speicherdauer der Daten, die Microsoft als eigenständig Verantwortlicher verarbeitet, ist nicht bekannt.
