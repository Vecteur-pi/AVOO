# Avoo App (Flutter)

Guide de configuration pour les developpeurs qui rejoignent ce projet.

## 1. Vue d'ensemble

Cette application mobile Flutter couvre principalement :
- Connexion avec Firebase Authentication
- Verification de profil et controle d'acces via Cloud Firestore
- Parcours d'inscription restaurant avec integration optionnelle de Supabase (OTP + upload du logo)

Configuration des plateformes dans le code actuel :
- Android est configure
- iOS/web/desktop ne sont pas configures pour Firebase dans `lib/firebase_options.dart`

## 2. Stack technique

- Flutter 3.x
- Dart 3.x
- Firebase Auth (connexion email/mot de passe)
- Cloud Firestore (lecture du profil utilisateur)
- Supabase (optionnel pour OTP d'inscription + stockage du logo)

## 3. Prerequis

Installez d'abord :
- Flutter SDK (le projet fonctionne actuellement avec Flutter `3.32.8`, Dart `3.8.1`)
- Android Studio (ou Android SDK + emulateur)
- JDK 11 (requis par la configuration Android Gradle)
- Git

Optionnel mais recommande :
- Firebase CLI et FlutterFire CLI
- Acces au dashboard Supabase

## 4. Cloner et installer

```bash
git clone <url-du-repo>
cd "New project"
flutter pub get
```

## 5. Configuration Firebase (obligatoire)

L'app initialise toujours Firebase dans `lib/main.dart`, donc une configuration Firebase valide est obligatoire.

### 5.1 Creer ou selectionner un projet Firebase

Utilisez un projet existant ou creez-en un nouveau.

### 5.2 Enregistrer l'application Android

Dans la console Firebase, ajoutez une app Android :
- Nom du package : `com.avoo.avoo`

Telechargez `google-services.json` puis placez-le ici :
- `android/app/google-services.json`

### 5.3 Generer les options Firebase Flutter

Depuis la racine du projet :

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android
```

Cela genere/met a jour :
- `lib/firebase_options.dart`

### 5.4 Activer les services utilises par l'application

Dans Firebase Console, activez :
- Authentication -> Sign-in method -> Email/Password
- Cloud Firestore -> Create database

### 5.5 Preparer des donnees Firestore minimales pour un utilisateur de test

Apres creation d'un utilisateur Firebase Auth, l'app attend des documents profil.

Minimum requis :
- Document `users/{uid}` avec le champ `restaurant_id` (ou `restaurantId`)
- Document `restaurants/{restaurant_id}/members/{uid}` ou `restaurants/{restaurant_id}/users/{uid}` avec les champs `name` (string), `role` (string) et `active` (bool)

Si ces documents sont absents, la connexion peut reussir mais l'application affichera des erreurs de profil/acces.

## 6. Configuration Supabase (optionnelle mais necessaire pour le flux d'inscription complet)

L'ecran d'inscription utilise `SupabaseRegistrationRepository`.
Sans variables Supabase, l'envoi/verif OTP et l'upload du logo echouent.
La soumission finale de l'inscription utilise actuellement un chemin mock et ne persiste pas encore un enregistrement backend reel.

### 6.1 Creer un projet Supabase

Recuperez :
- L'URL du projet
- La cle anon (publishable)

### 6.2 Configurer le bucket de stockage

Creez un bucket :
- Nom : `restaurant-logos`

L'application est actuellement configuree pour des URLs publiques (`publicBucket = true` dans `lib/supabase/supabase_config.dart`).

### 6.3 Configurer les dart-defines

Creez le fichier `dart_defines.json` a la racine du projet :

```json
{
  "SUPABASE_URL": "https://<votre-projet>.supabase.co",
  "SUPABASE_ANON_KEY": "<votre-cle-anon>"
}
```

## 7. Lancer l'application

### 7.1 Lancement standard (Firebase uniquement)

```bash
flutter run
```

### 7.2 Lancement avec variables Supabase

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### 7.3 Lancement sur un appareil specifique

```bash
flutter devices
flutter run -d <device_id> --dart-define-from-file=dart_defines.json
```

## 8. Commandes utiles (dev)

```bash
flutter pub get
flutter analyze
flutter test
flutter clean
```

Note : `test/widget_test.dart` est encore le test compteur par defaut et ne correspond pas a l'entree actuelle de l'application. Mettez les tests a jour avant d'utiliser `flutter test` en CI.

## 9. Depannage

- Erreur : `DefaultFirebaseOptions have not been configured for ...`
- Cause : execution sur une plateforme non configuree dans `lib/firebase_options.dart`.

- Erreur : profil manquant/inactif apres connexion
- Cause : documents Firestore utilisateur/resto manquants ou champ `active` a `false`.

- Erreur : `supabase_not_configured`
- Cause : variables `SUPABASE_URL`/`SUPABASE_ANON_KEY` manquantes.

- Erreur : Firestore `permission-denied`
- Cause : regles de securite Firestore qui ne permettent pas les lectures requises pour l'utilisateur connecte.

## 10. Structure du projet (zones principales)

- `lib/main.dart` : bootstrap de l'app (init Supabase optionnelle + init Firebase)
- `lib/auth/` : auth gate + chargement du profil utilisateur via Firestore
- `lib/login/` : interface de connexion
- `lib/registration/` : flux d'inscription en plusieurs etapes et repositories
- `lib/supabase/` : configuration Supabase
- `android/` : configuration native Android

## 11. Notes de securite

- Ne committez pas de secrets.
- Gardez les cles runtime dans des fichiers/variables locales autant que possible.
- `google-services.json`, `firebase_options.dart` et les fichiers de variables doivent etre geres par environnement.
