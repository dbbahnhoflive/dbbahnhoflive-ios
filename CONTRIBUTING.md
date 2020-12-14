Allgemein
=========

Danke für das Interesse an diesem Projekt! Für Anregungen, Verbesserungsvorschläge oder Bugs können gerne Issues eröffnet werden, um Code gerne ein Pull Request gestellt werden.

Die Codebasis ist über einen langen Zeitraum mit vielen verschiedenen Entwicklern gewachsen, daher befinden sich durchaus einige Altlasten im Code, die aber nicht als Vorbild für neue Entwicklungen anzusehen sind.

Es sind alle Hinweise und Regeln zu beachten die Apple für die Entwicklung von Apps vorgibt: [https://developer.apple.com/app-store/review/guidelines/](https://developer.apple.com/app-store/review/guidelines/)

Wie auch für Apples Review Guidelines, so gilt auch hier: "This is a living document".

Abhängigkeiten zu neuen Libraries sind möglichst zu vermeiden. Ggf. sollte hier vorher eine Abstimmung erfolgen ob eine neue Library im Projekt aufgenommen werden kann. Neben der Appgröße und Lizenzrechten spielt auch die Kompatibilität mit älteren iOS-Versionen eine wichtige Rollte. Libraries sollten möglichst unter Angabe einer konkreten Version im pod-File eingebunden werden.

Generell sind gängige Prinzipien für gute Software-Entwicklung zu beachten. Der Code sollte gut verständlich sein, "Copy+Paste" ist verboten usw.
Wir bevorzugen im Augenblick noch Objective-C Code vor Swift-Code. Zur Zeit enthält das Projekt 100% Objective-C Code. UI-Layout sollte möglichst Codebasiert unter Nutzung der Hilfsmethoden in UIView+Frame.h umgesetzt werden. Autolayout ist nur einzusetzen wenn der Code dadurch kürzer und verständlicher wird. UI-Code ist auf allen unterstützen Geräten zu testen, insbesondere auf den kleinsten und größten iPhone und iPad Auflösungen.

Sämtliche Änderungen und Erweiterungen des UI-Code müssen unter Nutzung von VoiceOver für Blinde oder Seheingeschränkte Nutzer gut zugänglich sein.
Der Code sollte in englischer Sprache geschrieben werden. Anzuzeigende Texte und VoiceOver sind zur Zeit nur Deutsch.
Neue Features sollten sowohl auf Dateiebene (Orderstruktur) als auch im Xcode-Projekt (Group) deutlich getrennt sein.
