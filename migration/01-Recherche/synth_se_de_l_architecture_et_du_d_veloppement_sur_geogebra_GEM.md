# Synthèse des échanges : Code source, Versions et Modularité de GeoGebra

Ce document résume les informations discutées concernant le logiciel mathématique GeoGebra, son fonctionnement open source, et les pistes pour le rendre modulaire d'un point de vue du développement.

## 1. Code Open Source et Licence
*   **Dépôt officiel :** Le code source de GeoGebra est disponible publiquement sur GitHub (`geogebra/geogebra`).
*   **Modèle de licence (Double licence) :**
    *   *Non commercial :* Le code est sous **GPLv3**, assujetti au *GeoGebra Non-Commercial License Agreement* (limité aux projets éducatifs, personnels ou à but non lucratif gratuits).
    *   *Ressources annexes :* Les traductions, installateurs et documentations sont souvent sous **CC BY-NC-SA**.
    *   *Commercial :* Toute intégration ou exploitation commerciale nécessite l'acquisition d'une **licence commerciale** spécifique auprès de GeoGebra.

## 2. Versions Actuelles
*   **Versions majeures de bureau :** GeoGebra Classic 6 (version 6.0.x) et GeoGebra Classic 5 (branche 5.2.x, maintenue activement pour son interface historique). Les deux partagent le même moteur mathématique.
*   **Versions spécifiques (ex: 5.4.934.0-d / Octobre 2026) :** La numérotation `5.4.x` couplée à un environnement récent (Java 25) correspond généralement aux **applications APK pour Android** (ex: 3D Calculator, Suite) ou à des builds spécifiques de test/découverte.

## 3. Personnalisation et "Plugins" dans la version de base
GeoGebra ne possède pas de système d'extensions classique au sens strict. La personnalisation passe par :
1.  **Outils personnalisés (Macros) :** Sauvegarde de constructions réutilisables.
2.  **Scripting intégré :** Injection de code JavaScript ou GeoGebra Script déclenché par des événements sur les objets.
3.  **API Web (JavaScript) :** Pilotage externe de l'applet via une page web.
4.  **Fork du code source :** Modification directe du monolithe en Java/GWT.

## 4. Rendre le code plus modulable
Pour créer un système d'extensions, trois architectures sont envisageables :
1.  **Architecture Web Découplée (Recommandée) :** Encapsuler l'applet web dans une application (React/Vue/JS) et développer les modules séparément qui interagiront via l'API JavaScript officielle.
2.  **Refonte du noyau Java (SPI) :** Pour la version bureau, utiliser le *Service Provider Interface* pour charger dynamiquement des extensions compilées.
3.  **Passerelle WebSocket / API Locale :** Créer un bridge pour piloter le moteur avec des scripts externes (Python, C#, etc.).

## 5. Environnement de Développement (Type Eclipse)
Le projet utilise **Gradle** comme outil de build, rendant l'environnement de développement indépendant de l'éditeur (Eclipse, VS Code, IntelliJ) :
*   Clonage via `git clone https://github.com/geogebra/geogebra.git`.
*   Importation en tant que "Projet Gradle existant" (avec Buildship sur Eclipse ou l'extension Java sur VS Code).
*   Lancement de la version bureau pour débogage via le terminal ou l'IDE : `.\gradlew :desktop:run`.

## 6. Intégration Gradle pour une approche modulaire
Pour reproduire le fonctionnement par "bundles" des applications RCP d'Eclipse, plusieurs outils s'intègrent à Gradle :
*   **PF4J (Plugin Framework for Java) :** Idéal et moderne, il isole chaque extension avec son propre *ClassLoader*.
*   **Plugin Gradle Bnd (OSGi) :** La méthode stricte pour générer des manifestes OSGi compatibles avec Equinox (la base d'Eclipse).
*   **API SPI Java :** Via les sous-projets Gradle et le `ServiceLoader` de Java.
*   **JPMS (Système de modules Java) :** Sécurisation et étanchéité des modules dès la compilation pour Java >= 11.