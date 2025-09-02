# 🚀 AutoTrello - Créateur Automatique de Cartes Trello

Un script PowerShell intelligent qui automatise la création de cartes Trello avec descriptions, checklists et labels. Parfait pour les projets, la gestion de tâches et l'organisation d'équipe.

## ✨ Fonctionnalités

- 🔐 **Authentification sécurisée** avec sauvegarde des identifiants
- 🎯 **Sélection interactive** des listes et labels disponibles
- 💾 **Configuration persistante** par board Trello
- 📝 **Création automatique** de cartes avec descriptions détaillées
- ✅ **Checklists "Definition of Done"** intégrées
- 🏷️ **Application automatique** de labels personnalisés
- 🔄 **Gestion intelligente** des erreurs et fallbacks

## 📋 Prérequis

- **PowerShell 5.1+** (Windows 10/11, Windows Server 2016+)
- **Compte Trello** actif
- **Connexion Internet** pour l'API Trello
- **Permissions d'écriture** sur le board cible

## 🔑 Récupération des Identifiants Trello

### 1. Obtenir votre API Key

1. Rendez-vous sur [https://trello.com/app-key](https://trello.com/app-key)
2. Connectez-vous à votre compte Trello
3. Cliquez sur **"Portail administrateur du Power-Up"**
4. Cliquez sur **"Nouveau Power-up ou nouvelle intégration"**
5. Remplissez le formulaire :
   - **Nom** : `AutoTrello` (ou le nom de votre choix)
   - **Espace de travail** : Sélectionnez votre espace de travail
   - **E-mail** : Votre adresse e-mail
   - **Contact d'assistance** : Votre e-mail de support
   - **Auteur** : Votre nom ou nom d'entreprise
   - **URL du connecteur Iframe** : Laissez vide
6. Cliquez sur **"Créer"**
7. Dans votre projet créé, allez dans **"Clé API"**
8. **Copiez la "API Key"** affichée (chaîne de 32 caractères)

### 2. Générer votre Token

1. Remplacez `YOUR_KEY` par votre API Key dans cette URL :
   ```
   https://trello.com/1/authorize?expiration=never&name=LitchiCardSeeder&scope=read,write&response_type=token&key=YOUR_KEY
   ```
2. Collez l'URL complète dans votre navigateur
3. Autorisez l'application à accéder à votre compte Trello
4. **Copiez le "Token"** généré (chaîne commençant par "ATTA...")

### 3. Récupérer l'URL du Board

1. Ouvrez votre board Trello dans le navigateur
2. **Copiez l'URL complète** depuis la barre d'adresse
   - Format : `https://trello.com/b/XXXXX/nom-du-board`
   - Ou juste le shortLink : `XXXXX`

## 🚀 Installation et Utilisation

### 1. Téléchargement

```bash
git clone https://github.com/votre-username/AutoTrello.git
cd AutoTrello
```

### 2. Première Exécution

1. **Ouvrez PowerShell** (ou PowerShell ISE)
2. **Naviguez vers le dossier** du projet
3. **Exécutez le script** :

```powershell
.\AutoTrello-Working.ps1
```

### 3. Configuration Initiale

Le script vous demandera :
- **Votre API Key Trello**
- **Votre Token Trello**
- **L'URL de votre board**
- **Sauvegarder la configuration ?** → Répondez **"O"** (Oui)

### 4. Sélection Interactive

- **Liste cible** : Choisissez parmi les listes disponibles sur votre board
- **Label** : Sélectionnez un label existant ou créez-en un nouveau
- **Couleur** : Choisissez la couleur du label (si création)

### 5. Création des Labels (Recommandé)

**⚠️ Important** : Pour éviter les erreurs, créez vos labels **manuellement** sur Trello avant d'exécuter le script :

1. **Ouvrez votre board Trello** dans le navigateur
2. **Cliquez sur "Afficher le menu"** (3 points en haut à droite)
3. **Sélectionnez "Étiquettes"**
4. **Cliquez sur "Créer une nouvelle étiquette"**
5. **Donnez un nom** à votre label
6. **Choisissez une couleur** (évitez les couleurs déjà utilisées)
7. **Cliquez sur "Créer"**

**Avantages de la création manuelle :**
- ✅ Évite les erreurs d'API Trello
- ✅ Contrôle total sur les noms et couleurs
- ✅ Pas de conflits de permissions
- ✅ Plus rapide et fiable

## 📁 Structure des Fichiers

```
AutoTrello/
├── AutoTrello-Working.ps1    # Script principal
├── trello-config.json        # Configuration globale (KEY, TOKEN)
├── board-config-*.json       # Configurations spécifiques par board
└── README.md                 # Ce fichier
```

## ⚙️ Configuration Avancée

### Variables d'Environnement (Optionnel)

Vous pouvez définir vos identifiants comme variables d'environnement :

```powershell
$env:TRELLO_KEY = "votre-api-key"
$env:TRELLO_TOKEN = "votre-token"
```

### Personnalisation des Cartes

**📍 Localisation** : Dans le script `AutoTrello-Working.ps1`, cherchez la section :

```powershell
# -------------------- ZONE À MODIFIER : tes cartes --------------------
```

**📝 Structure d'une carte** : Chaque carte suit ce format :

```powershell
@{
  title = "Titre de votre carte"
  desc  = @"
Description détaillée de la carte
sur plusieurs lignes si nécessaire
"@
  dod   = @(
    "Critère 1 de la Definition of Done",
    "Critère 2 de la Definition of Done",
    "Critère 3 de la Definition of Done"
  )
}
```

**🔧 Comment modifier :**

1. **Titre** (`title`) : Nom court et descriptif de la carte
2. **Description** (`desc`) : Détails complets de la tâche ou fonctionnalité
3. **Definition of Done** (`dod`) : Liste des critères de validation

**📋 Exemple concret :**

```powershell
@{
  title = "Interface utilisateur responsive"
  desc  = @"
Créer une interface utilisateur qui s'adapte à tous les écrans :
- Mobile (320px - 768px)
- Tablette (768px - 1024px) 
- Desktop (1024px+)
- Tests sur navigateurs Chrome, Firefox, Safari
"@
  dod   = @(
    "Design mobile-first implémenté",
    "Breakpoints CSS définis et testés",
    "Navigation adaptative fonctionnelle",
    "Tests cross-browser validés",
    "Documentation responsive rédigée"
  )
}
```

**⚠️ Points importants :**
- **Gardez la structure** avec `@{}` et les propriétés `title`, `desc`, `dod`
- **Utilisez `@"..."@`** pour les descriptions multi-lignes
- **Ajoutez des virgules** entre chaque carte
- **Testez le script** après modification pour vérifier la syntaxe

## 🔧 Dépannage

### Erreur "AmpersandNotAllowed"

**Problème** : PowerShell refuse le caractère `&` dans les URLs
**Solution** : Utilisez `AutoTrello-Working.ps1` (version corrigée)

### Erreur d'Encodage Unicode

**Problème** : PowerShell ISE demande de changer l'encodage
**Solution** : Cliquez sur **"OK"** pour passer en format Unicode

### Erreur 401 (Non autorisé)

**Problème** : Identifiants Trello incorrects
**Solution** : Vérifiez votre API Key et Token

### Erreur 404 (Board non trouvé)

**Problème** : URL du board incorrecte ou permissions insuffisantes
**Solution** : Vérifiez l'URL et vos droits d'accès au board

### Erreur 400 sur les Labels

**Problème** : Conflit de couleur sur le board ou permissions insuffisantes
**Solution** : 
1. **Recommandé** : Créez vos labels manuellement sur Trello (voir section "Création des Labels")
2. **Alternative** : Le script propose automatiquement des solutions (création manuelle, sélection existante, ou continuation sans label)

## 📊 Exemples d'Utilisation

### Création de Cartes de Projet

```powershell
# Le script crée automatiquement :
# - 5 cartes de spécification dashboard (par défaut)
# - Chaque carte avec description détaillée
# - Checklist "DoD" avec 6 critères
# - Label appliqué automatiquement

# Pour personnaliser, modifiez la section :
# -------------------- ZONE À MODIFIER : tes cartes --------------------
# dans le script AutoTrello-Working.ps1
```

### Personnalisation des Cartes

**🎯 Cas d'usage courants :**

- **Sprint Planning** : User stories avec critères d'acceptation
- **Développement** : Tâches techniques avec étapes de validation
- **Documentation** : Sections à rédiger avec points de contrôle
- **Tests** : Scénarios de test avec critères de réussite
- **Déploiement** : Étapes de mise en production

**💡 Conseils de rédaction :**

- **Titre** : Court, clair, actionnable
- **Description** : Contexte, objectifs, contraintes
- **DoD** : Critères mesurables et vérifiables

### Gestion d'Équipe

```powershell
# Utilisez pour :
# - Sprint planning
# - User stories
# - Tâches techniques
# - Documentation
# - Tests et validation
```

## 🔒 Sécurité

- **Les identifiants sont sauvegardés localement** uniquement
- **Aucune transmission** vers des serveurs tiers
- **Permissions minimales** sur votre compte Trello
- **Suppression facile** des configurations sauvegardées

## 🤝 Contribution

1. **Fork** le projet
2. **Créez une branche** pour votre fonctionnalité
3. **Commitez** vos changements
4. **Poussez** vers la branche
5. **Ouvrez une Pull Request**

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

- **Issues GitHub** : [Créer une issue](https://github.com/votre-username/AutoTrello/issues)
- **Wiki** : Documentation détaillée
- **Discussions** : Questions et réponses

## 🙏 Remerciements

- **Trello** pour leur API robuste
- **PowerShell** pour la puissance du scripting
- **Communauté open source** pour les contributions

---

**⭐ N'oubliez pas de mettre une étoile au projet si il vous est utile !**

**🔄 Dernière mise à jour** : $(Get-Date -Format "yyyy-MM-dd")
