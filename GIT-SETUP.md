# 🚀 Instructions de Déploiement Git

## 📋 Prérequis

### 1. Installer Git
Si Git n'est pas installé sur votre système :

**Windows :**
1. Téléchargez Git depuis [https://git-scm.com/download/win](https://git-scm.com/download/win)
2. Installez avec les options par défaut
3. Redémarrez PowerShell après l'installation

**Vérification :**
```powershell
git --version
```

## 🔧 Commandes Git à exécuter

Une fois Git installé, exécutez ces commandes dans l'ordre :

```bash
# 1. Initialiser le repository Git
git init

# 2. Ajouter tous les fichiers (sauf ceux du .gitignore)
git add .

# 3. Premier commit
git commit -m "Initial commit: AutoTrello PowerShell script"

# 4. Renommer la branche principale en 'main'
git branch -M main

# 5. Ajouter le remote origin
git remote add origin https://github.com/Lasdecoeur-R/Trello-Auto-Cards.git

# 6. Pousser vers GitHub
git push -u origin main
```

## 📁 Fichiers inclus dans le commit

- ✅ `AutoTrello-Working.ps1` - Script principal
- ✅ `README.md` - Documentation complète
- ✅ `.gitignore` - Exclusion des fichiers sensibles
- ✅ `GIT-SETUP.md` - Ce fichier d'instructions

## 🚫 Fichiers exclus (via .gitignore)

- ❌ `trello-config.json` - Contient vos clés API (sensible !)
- ❌ `board-config-*.json` - Configurations spécifiques aux boards
- ❌ Fichiers temporaires et de cache

## 🔒 Sécurité

**IMPORTANT :** Le fichier `trello-config.json` contient vos identifiants Trello et ne sera **JAMAIS** poussé sur GitHub grâce au `.gitignore`.

## 📝 Prochaines étapes

1. **Installez Git** si ce n'est pas déjà fait
2. **Exécutez les commandes** ci-dessus
3. **Vérifiez sur GitHub** que votre projet est bien en ligne
4. **Supprimez ce fichier** `GIT-SETUP.md` après déploiement

## 🆘 En cas de problème

- **Erreur "remote already exists"** : `git remote remove origin` puis recommencez
- **Erreur d'authentification** : Utilisez un token GitHub personnel
- **Fichiers non ajoutés** : Vérifiez le `.gitignore`

---

**🎉 Votre projet AutoTrello sera bientôt en ligne sur GitHub !**
