# ============================================================================
# TRELLO – Trello Card Seeder (générique, compatible PowerShell ISE 5.1)
# - Demande : KEY, TOKEN, Board (URL/shortLink), Nom de liste, Nom du label, Couleur (menu).
# - GET corrigé : key/token en query string (évite 404).
# - Gère le cas Trello 400 sur /labels si la couleur existe déjà sur le board :
#     * cherche par nom, puis par couleur
#     * si couleur existante => tentative de renommage ; sinon réutilise
#     * fallback : crée label sans couleur si tout échoue
# - Crée chaque carte + description + checklist "DoD", applique le label si fourni.
# - NOUVEAU : Sauvegarde l'URL du board et sélection interactive des listes/labels
# ============================================================================

# Encodage : ISE n'a pas de vrai ConsoleHost -> protège l'appel
try { if ($host.Name -eq 'ConsoleHost') { [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8 } } catch {}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# -------------------- Gestion des identifiants Trello --------------------
# Utiliser le répertoire courant si $PSScriptRoot est vide
$ScriptDir = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { Get-Location } else { $PSScriptRoot }
$ConfigFile = Join-Path $ScriptDir "trello-config.json"

function Load-TrelloConfig {
  Write-Host "Recherche du fichier de configuration : $ConfigFile" -ForegroundColor Gray
  if (Test-Path $ConfigFile) {
    Write-Host "Fichier de configuration trouvé" -ForegroundColor Green
    try {
      $config = Get-Content $ConfigFile | ConvertFrom-Json
      Write-Host "Configuration chargée avec succès" -ForegroundColor Green
      return $config
    } catch {
      Write-Warning "Fichier de configuration corrompu, sera recréé. Erreur: $($_.Exception.Message)"
    }
  } else {
    Write-Host "Fichier de configuration non trouvé" -ForegroundColor Yellow
  }
  return $null
}

function Save-TrelloConfig {
  param([string]$Key, [string]$Token, [string]$BoardUrl)
  $config = @{
    Key = $Key
    Token = $Token
    BoardUrl = $BoardUrl
    LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  }
  $config | ConvertTo-Json | Set-Content $ConfigFile -Encoding UTF8
  Write-Host "✅ Configuration Trello sauvegardée localement" -ForegroundColor Green
}

function Load-BoardConfig {
  param([string]$BoardUrl)
  $configFile = Join-Path $ScriptDir "board-config-$BoardUrl.json"
  if (Test-Path $configFile) {
    try {
      $config = Get-Content $configFile | ConvertFrom-Json
      Write-Host "Configuration du board trouvée : $BoardUrl" -ForegroundColor Green
      return $config
    } catch {
      Write-Warning "Fichier de configuration du board corrompu : $configFile. Erreur: $($_.Exception.Message)"
    }
  } else {
    Write-Host "Aucune configuration du board trouvée pour $BoardUrl" -ForegroundColor Yellow
  }
  return $null
}

function Save-BoardConfig {
  param([string]$BoardUrl, [string]$ListName, [string]$LabelName, [string]$LabelColor)
  $config = @{
    ListName = $ListName
    LabelName = $LabelName
    LabelColor = $LabelColor
  }
  $config | ConvertTo-Json | Set-Content (Join-Path $ScriptDir "board-config-$BoardUrl.json") -Encoding UTF8
  Write-Host "✅ Configuration du board sauvegardée localement : $BoardUrl" -ForegroundColor Green
}

Write-Host "=== CONFIGURATION TRELLO ===" -ForegroundColor Cyan
Write-Host "Pour obtenir votre KEY et TOKEN, allez sur : https://trello.com/app-key" -ForegroundColor Yellow

# Charger la configuration existante
$savedConfig = Load-TrelloConfig
$Key = $null
$Token = $null

if ($savedConfig -and $savedConfig.Key -and $savedConfig.Token) {
  Write-Host "Configuration trouvée du $($savedConfig.LastUpdated)" -ForegroundColor Green
  Write-Host "Options :" -ForegroundColor Cyan
  Write-Host "  [O] Utiliser les identifiants sauvegardés" -ForegroundColor White
  Write-Host "  [N] Saisir de nouveaux identifiants" -ForegroundColor White
  Write-Host "  [M] Modifier la configuration existante" -ForegroundColor White
  
  $choice = Read-Host "Votre choix (O/n/m)"
  
  if ($choice -eq "" -or $choice -eq "O" -or $choice -eq "o") {
    $Key = $savedConfig.Key
    $Token = $savedConfig.Token
    Write-Host "✅ Utilisation des identifiants sauvegardés" -ForegroundColor Green
  } elseif ($choice -eq "M" -or $choice -eq "m") {
    Write-Host "Modification de la configuration..." -ForegroundColor Yellow
    $Key = Read-Host "Nouvelle Trello API KEY"
    $Token = Read-Host "Nouveau Trello TOKEN"
    $BoardUrl = Read-Host "URL du board Trello (ex: https://trello.com/b/XXXXX)"
    Save-TrelloConfig -Key $Key -Token $Token -BoardUrl $BoardUrl
  }
  # Si choix "N", on continue vers la saisie des identifiants
} else {
  Write-Host "Aucune configuration sauvegardée trouvée." -ForegroundColor Yellow
}

# Si pas de configuration sauvegardée ou refusée, demander les identifiants
if (-not $Key -or -not $Token) {
  $Key = Read-Host "Trello API KEY (laisser vide pour utiliser `$env:TRELLO_KEY)"
  if ([string]::IsNullOrWhiteSpace($Key)) { $Key = $env:TRELLO_KEY }
  if ([string]::IsNullOrWhiteSpace($Key)) { throw "Aucune KEY fournie." }

  $Token = Read-Host "Trello TOKEN (laisser vide pour utiliser `$env:TRELLO_TOKEN)"
  if ([string]::IsNullOrWhiteSpace($Token)) { $Token = $env:TRELLO_TOKEN }
  if ([string]::IsNullOrWhiteSpace($Token)) { throw "Aucun TOKEN fourni." }

  # Sauvegarder les nouveaux identifiants
  $saveConfig = Read-Host "Sauvegarder ces identifiants pour la prochaine fois ? (O/n)"
  if ($saveConfig -eq "" -or $saveConfig -eq "O" -or $saveConfig -eq "o") {
    $BoardUrl = Read-Host "URL du board Trello (ex: https://trello.com/b/XXXXX)"
    Save-TrelloConfig -Key $Key -Token $Token -BoardUrl $BoardUrl
  }
}

# Board : URL ou shortLink (après /b/)
if ($savedConfig -and $savedConfig.BoardUrl) {
  Write-Host "Board sauvegardé : $($savedConfig.BoardUrl)" -ForegroundColor Green
  $useSavedBoard = Read-Host "Utiliser ce board ? (O/n)"
  if ($useSavedBoard -eq "" -or $useSavedBoard -eq "O" -or $useSavedBoard -eq "o") {
    $BoardInput = $savedConfig.BoardUrl
  } else {
    $BoardInput = Read-Host "URL du board Trello (ou juste le shortLink après /b/)"
  }
} else {
  $BoardInput = Read-Host "URL du board Trello (ou juste le shortLink après /b/)"
}

if ($BoardInput -match 'trello\.com/b/([^/]+)') { 
  $BoardId = $Matches[1] 
  $BoardUrl = $BoardInput
} else { 
  $BoardId = $BoardInput.Trim() 
  $BoardUrl = "https://trello.com/b/$BoardId"
}
if ([string]::IsNullOrWhiteSpace($BoardId)) { throw "BoardId manquant." }

# -------------------- Helpers --------------------
function Join-QueryString {
  param([hashtable]$Params)
  ($Params.GetEnumerator() | ForEach-Object {
    [System.Uri]::EscapeDataString($_.Key) + "=" + [System.Uri]::EscapeDataString([string]$_.Value)
  }) -join "&"
}

function Select-ListFromBoard {
  param([string]$BoardId)
  Write-Host "`n📋 Récupération des listes disponibles..." -ForegroundColor Cyan
  try {
    $baseUrl = "https://api.trello.com/1/boards/$BoardId/lists"
    $queryParams = "fields=name,id,pos"
    $fullUrl = "$baseUrl`?$queryParams"
    $lists = Invoke-Trello $fullUrl
    if ($lists.Count -eq 0) {
      Write-Host "Aucune liste trouvée sur ce board" -ForegroundColor Yellow
      return $null
    }
    
    Write-Host "`nListes disponibles sur le board :" -ForegroundColor Cyan
    for ($i = 0; $i -lt $lists.Count; $i++) {
      $list = $lists[$i]
      Write-Host ("[{0}] {1}" -f ($i + 1), $list.name) -ForegroundColor White
    }
    
    $choice = Read-Host "`nSélectionnez le numéro de la liste (1-$($lists.Count))"
    $index = [int]$choice - 1
    
    if ($index -ge 0 -and $index -lt $lists.Count) {
      $selectedList = $lists[$index]
      Write-Host ("✅ Liste sélectionnée : {0}" -f $selectedList.name) -ForegroundColor Green
      return $selectedList
    } else {
      throw "Sélection invalide"
    }
  } catch {
    Write-Warning "Erreur lors de la récupération des listes : $($_.Exception.Message)"
    return $null
  }
}

function Select-LabelFromBoard {
  param([string]$BoardId)
  Write-Host "`n🏷️ Récupération des labels disponibles..." -ForegroundColor Cyan
  try {
    $baseUrl = "https://api.trello.com/1/boards/$BoardId/labels"
    $limit = "limit=1000"
    $fields = "fields=id,name,color"
    $queryParams = "$limit" + "&" + "$fields"
    $fullUrl = "$baseUrl`?$queryParams"
    $labels = Invoke-Trello $fullUrl
    if ($labels.Count -eq 0) {
      Write-Host "Aucun label trouvé sur ce board" -ForegroundColor Yellow
      return $null
    }
    
    Write-Host "`nLabels disponibles sur le board :" -ForegroundColor Cyan
    Write-Host "[0] Aucun label" -ForegroundColor White
    for ($i = 0; $i -lt $labels.Count; $i++) {
      $label = $labels[$i]
      $name = if ($label.name) { "'$($label.name)'" } else { "Sans nom" }
      $color = if ($label.color) { $label.color } else { "Aucune" }
      Write-Host ("[{0}] {1} (couleur: {2})" -f ($i + 1), $name, $color) -ForegroundColor White
    }
    
    $choice = Read-Host "`nSélectionnez le numéro du label (0-$($labels.Count))"
    $index = [int]$choice - 1
    
    if ($index -eq -1) {
      Write-Host "✅ Aucun label sélectionné" -ForegroundColor Green
      return $null
    } elseif ($index -ge 0 -and $index -lt $labels.Count) {
      $selectedLabel = $labels[$index]
      Write-Host ("✅ Label sélectionné : {0} (couleur: {1})" -f $selectedLabel.name, $selectedLabel.color) -ForegroundColor Green
      return $selectedLabel
    } else {
      throw "Sélection invalide"
    }
  } catch {
    Write-Warning "Erreur lors de la récupération des labels : $($_.Exception.Message)"
    return $null
  }
}

function Invoke-Trello {
  param(
    [Parameter(Mandatory)][string]$Uri,
    [ValidateSet('GET','POST','PUT','DELETE')][string]$Method='GET',
    [hashtable]$Body
  )
  $p = @{}; $p.key = $Key; $p.token = $Token
  if ($Body) { foreach($k in $Body.Keys){ $p[$k] = $Body[$k] } }

  try {
    if ($Method -eq 'GET') {
      $qs = Join-QueryString $p
      $sep = '?'; if ($Uri -match '\?') { $sep = '&' }
      $full = "$Uri$sep$qs"
      Write-Verbose "Appel GET: $full"
      return Invoke-RestMethod -Method GET -Uri $full -ErrorAction Stop
    } else {
      Write-Verbose ("Appel {0}: {1}" -f $Method, $Uri)
      return Invoke-RestMethod -Method $Method -Uri $Uri -Body $p -ErrorAction Stop
    }
  } catch {
    # Affiche le détail JSON renvoyé par Trello si dispo
    try {
      if ($_.Exception.Response) {
        $respStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($respStream)
        $body = $reader.ReadToEnd()
        Write-Warning "Réponse Trello: $body"
      }
    } catch {}
    
    $errorMsg = "Trello API error ($Method $Uri): $($_.Exception.Message)"
    if ($_.Exception.Response) {
      $errorMsg += " (HTTP $($_.Exception.Response.StatusCode))"
    }
    throw $errorMsg
  }
}

function Get-OrCreate-ListId {
  param([string]$BoardId,[string]$ListName)
  $baseUrl = "https://api.trello.com/1/boards/$BoardId/lists"
  $queryParams = "fields=name,id"
  $fullUrl = "$baseUrl`?$queryParams"
  $lists = Invoke-Trello $fullUrl
  $id = ($lists | Where-Object { $_.name -eq $ListName }).id
  if (-not $id) {
    $created = Invoke-Trello -Method POST -Uri "https://api.trello.com/1/lists" -Body @{ name=$ListName; idBoard=$BoardId; pos="top" }
    $id = $created.id
  }
  $id
}

function Get-OrCreate-LabelId {
  param([string]$BoardId,[string]$Name,[string]$Color)

  if ([string]::IsNullOrWhiteSpace($Name)) { return $null }
  
  # Nettoyer le nom du label
  $Name = $Name.Trim()
  if ([string]::IsNullOrWhiteSpace($Name)) { return $null }
  
  Write-Host "🎯 CRÉATION FORCÉE d'un nouveau label" -ForegroundColor Cyan
  Write-Host "Nom demandé: '$Name'" -ForegroundColor White
  Write-Host "Couleur demandée: '$Color'" -ForegroundColor White
  
  # Nettoyer le nom (juste enlever les retours à la ligne)
  $CleanName = $Name -replace '[\r\n]', ' '
  $CleanName = $CleanName.Trim()
  
  # Créer le label avec VOTRE nom et VOTRE couleur
  try {
    if ($Color -eq "null") {
      # Sans couleur
      $lab = Invoke-Trello -Method POST -Uri "https://api.trello.com/1/labels" -Body @{ 
        name=$CleanName; 
        idBoard=$BoardId 
      }
      Write-Host "✅ Label créé SANS couleur (ID: $($lab.id))" -ForegroundColor Green
    } else {
      # AVEC couleur
      $lab = Invoke-Trello -Method POST -Uri "https://api.trello.com/1/labels" -Body @{ 
        name=$CleanName; 
        color=$Color; 
        idBoard=$BoardId 
      }
      Write-Host "✅ Label créé AVEC couleur '$Color' (ID: $($lab.id))" -ForegroundColor Green
    }
    
    Write-Host "  Nom dans Trello: '$($lab.name)'" -ForegroundColor Gray
    Write-Host "  Couleur dans Trello: '$($lab.color)'" -ForegroundColor Gray
    
    return $lab.id
    
  } catch {
    Write-Host "❌ ÉCHEC de la création du label" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    
    # Si l'API refuse, proposer des solutions
    Write-Host "`n🔧 SOLUTIONS :" -ForegroundColor Cyan
    Write-Host "1. Créer le label MANUELLEMENT sur le board" -ForegroundColor White
    Write-Host "2. Utiliser un label existant" -ForegroundColor White
    Write-Host "3. Continuer sans label" -ForegroundColor White
    
    $choice = Read-Host "`nVotre choix (1/2/3)"
    
    if ($choice -eq "1") {
      Write-Host "`n📋 INSTRUCTIONS MANUELLES :" -ForegroundColor Cyan
      Write-Host "1. Ouvrez votre board Trello dans le navigateur" -ForegroundColor White
      Write-Host "2. Cliquez sur 'Afficher le menu' (3 points en haut à droite)" -ForegroundColor White
      Write-Host "3. Sélectionnez 'Étiquettes'" -ForegroundColor White
      Write-Host "4. Cliquez sur 'Créer une nouvelle étiquette'" -ForegroundColor White
      Write-Host "5. Nom : '$CleanName'" -ForegroundColor White
      Write-Host "6. Couleur : $Color" -ForegroundColor White
      Write-Host "7. Cliquez sur 'Créer'" -ForegroundColor White
      Write-Host "8. Relancez ce script après création" -ForegroundColor White
      
      Write-Host "`nAppuyez sur Entrée pour quitter..." -ForegroundColor Cyan
      Read-Host
      exit 0
      
    } elseif ($choice -eq "2") {
      Write-Host "`nSélection d'un label existant..." -ForegroundColor Cyan
      $baseUrl = "https://api.trello.com/1/boards/$BoardId/labels"
      $limit = "limit=1000"
      $fields = "fields=id,name,color"
      $queryParams = "$limit" + "&" + "$fields"
      $fullUrl = "$baseUrl`?$queryParams"
      $labels = Invoke-Trello $fullUrl
      $labels | ForEach-Object { 
        $name = if ($_.name) { "'$($_.name)'" } else { "Sans nom" }
        Write-Host "ID: $($_.id) | Nom: $name | Couleur: $($_.color)" -ForegroundColor White
      }
      
      $selectedId = Read-Host "Entrez l'ID du label à utiliser"
      $selectedLabel = $labels | Where-Object { $_.id -eq $selectedId } | Select-Object -First 1
      
      if ($selectedLabel) {
        Write-Host "✅ Label sélectionné : $($selectedLabel.id)" -ForegroundColor Green
        return $selectedLabel.id
      } else {
        throw "ID de label invalide"
      }
      
    } else {
      Write-Host "✅ Continuation sans label" -ForegroundColor Green
      return $null
    }
  }
}

function New-TrelloCard {
  param([string]$Title,[string]$Desc,[string]$ListId)
  Invoke-Trello -Method POST -Uri "https://api.trello.com/1/cards" -Body @{ name=$Title; desc=$Desc; idList=$ListId }
}

function Add-Checklist {
  param([string]$CardId,[string]$ChecklistName,[string[]]$Items)
  if (-not $Items -or $Items.Count -eq 0) { return }
  $cl = Invoke-Trello -Method POST -Uri "https://api.trello.com/1/cards/$CardId/checklists" -Body @{ name=$ChecklistName }
  foreach ($i in $Items) {
    Invoke-Trello -Method POST -Uri "https://api.trello.com/1/checklists/$($cl.id)/checkItems" -Body @{ name=$i } | Out-Null
  }
}

function Add-LabelToCard {
  param([string]$CardId,[string]$LabelId)
  if ([string]::IsNullOrWhiteSpace($LabelId)) { return }
  try {
    Invoke-Trello -Method POST -Uri "https://api.trello.com/1/cards/$CardId/idLabels" -Body @{ value=$LabelId } | Out-Null
    Write-Host "  🏷️ Label appliqué à la carte" -ForegroundColor Green
  } catch {
    Write-Warning "  ⚠️ Impossible d'appliquer le label: $($_.Exception.Message)"
  }
}

# Liste cible
$savedBoardConfig = Load-BoardConfig -BoardUrl $BoardUrl
if ($savedBoardConfig -and $savedBoardConfig.ListName) {
  Write-Host "Liste sauvegardée : $($savedBoardConfig.ListName)" -ForegroundColor Green
  $useSavedList = Read-Host "Utiliser cette liste ? (O/n)"
  if ($useSavedList -eq "" -or $useSavedList -eq "O" -or $useSavedList -eq "o") {
    $selectedList = @{ name = $savedBoardConfig.ListName; id = $null }
  } else {
    $selectedList = Select-ListFromBoard -BoardId $BoardId
  }
} else {
  $selectedList = Select-ListFromBoard -BoardId $BoardId
}

if (-not $selectedList) { throw "Aucune liste sélectionnée." }
$TargetListName = $selectedList.name

# Label (nom + couleur via menu)
if ($savedBoardConfig -and $savedBoardConfig.LabelName) {
  Write-Host "Label sauvegardé : $($savedBoardConfig.LabelName) (couleur: $($savedBoardConfig.LabelColor))" -ForegroundColor Green
  $useSavedLabel = Read-Host "Utiliser ce label ? (O/n)"
  if ($useSavedLabel -eq "" -or $useSavedLabel -eq "O" -or $useSavedLabel -eq "o") {
    $selectedLabel = @{ name = $savedBoardConfig.LabelName; color = $savedBoardConfig.LabelColor; id = $null }
  } else {
    $selectedLabel = Select-LabelFromBoard -BoardId $BoardId
  }
} else {
  $selectedLabel = Select-LabelFromBoard -BoardId $BoardId
}

$LabelName = $null
$LabelColor = $null
if ($selectedLabel) {
  $LabelName = $selectedLabel.name
  $LabelColor = $selectedLabel.color
}

$SleepBetween = 0.35
$ChecklistName = "DoD"

# -------------------- ZONE À MODIFIER : tes cartes --------------------
$Cards = @(
  @{
    title = "KPI par rôle (User/Tech/Manager/RH/Admin)"
    desc  = @"
Cette carte définit les indicateurs affichés sur le dashboard en fonction du rôle. Pour l'Utilisateur : tickets ouverts, derniers documents, notifications non lues. Pour le Technicien : tickets assignés/en retard, MTTR/âge moyen, équipements en panne. Pour le Manager : charge par technicien, SLA tenus, tendances mensuelles. Pour la RH : nouveaux comptes, comptes inactifs, événements/planning. Pour l'Admin : sessions actives, erreurs système, licences proches d'expiration. Chaque KPI précise la définition, la source de données, la période (jour/semaine/mois) et le mode d'actualisation afin de garantir une lecture fiable et comparable.
"@
    dod   = @(
      "Liste des KPI par rôle rédigée avec définition, formule et période (doc /docs/dashboard/kpi-par-role.md).",
      "Source de données et requêtes identifiées pour chaque KPI (tables, vues, agrégations).",
      "Seuils/états (OK/attention/critique) documentés, avec légende cohérente.",
      "Cas 'données vides' et 'erreur de chargement' prévus avec messages clairs.",
      "Budget perf noté (latence cible p95) et respecté sur dataset d'essai.",
      "Validation PO/Stakeholders (par rôle) consignée avec exemples d'écran."
    )
  },
  @{
    title = "Graphes (tendances, répartitions)"
    desc  = @"
Cette carte spécifie les visualisations principales du dashboard : courbes de tendance (tickets créés/résolus, activité login), barres empilées (répartition par priorité, par site/région), camemberts/donut pour la part de catégories, et cartes thermiques simples si nécessaire. Les axes, légendes, unités, périodes de comparaison (N vs N-1) et règles d'accessibilité (contraste, alternative textuelle) sont définis. Le style visuel respecte les tokens glassmorphism sans nuire à la lisibilité.
"@
    dod   = @(
      "Catalogue de graphes défini (type, métrique, période, axes, légendes) dans /docs/dashboard/graphs-spec.md.",
      "États de chargement/vide/erreur modélisés pour chaque graphique.",
      "Règles d'accessibilité documentées (contraste, descriptions textuelles).",
      "Exemples comparatifs N vs N-1 ou rolling window précisés.",
      "Tests de performance (temps de rendu) et limites de points par graph fixés.",
      "Validation UX/PO sur lisibilité et cohérence visuelle."
    )
  },
  @{
    title = "Alertes (urgences, expirations, incidents)"
    desc  = @"
Cette carte décrit les alertes à remonter sur le dashboard : tickets urgents (P0/P1) non pris en charge, licences arrivant à expiration, équipements/agents offline au-delà du seuil, erreurs système récentes. Chaque alerte précise son déclencheur, sa priorité, son destinataire potentiel et sa durée de visibilité. Les messages doivent être concis, actionnables (liens vers la vue concernée) et respecter le périmètre de droits, pour éviter toute divulgation d'informations sensibles.
"@
    dod   = @(
      "Table de règles d'alertes rédigée (déclencheur, seuil, priorité, destinataires) /docs/dashboard/alerts.md.",
      "Affichage des alertes contextualisé par rôle et périmètre (RBAC respecté).",
      "Lien d'action direct depuis l'alerte (ex.: ouvrir ticket, page licence).",
      "Gestion d'acknowledgement/masquage temporaire documentée si applicable.",
      "Jeu d'essai couvrant urgences, expirations et incidents simulés.",
      "Validation Sec/PO (pas d'exposition d'infos hors périmètre)."
    )
  },
  @{
    title = "Quick actions (contextuelles)"
    desc  = @"
Cette carte définit la zone d'actions rapides du dashboard, adaptée au rôle et au contexte. Exemples : l'Utilisateur crée un ticket, le Technicien ouvre sa file et planifie une intervention, le Manager génère un rapport d'équipe, la RH ajoute un document/planning, l'Admin lance une sauvegarde ou accède à la configuration. Les actions doivent être claires, limitées en nombre, protégées par confirmation quand c'est sensible, et toujours conformes aux permissions effectives.
"@
    dod   = @(
      "Matrice des quick actions par rôle documentée (/docs/dashboard/quick-actions.md) avec icônes et libellés.",
      "Règles de garde-fous (confirmations, restrictions) notées pour actions sensibles.",
      "Indisponibles non affichées (pas de bouton grisé pour actions interdites).",
      "Parcours post-action (feedback/toast, redirection) défini et cohérent.",
      "Tests E2E de présence/absence par rôle et vérification d'accès côté serveur.",
      "Validation UX/PO (clarté, nombre raisonnable d'actions)."
    )
  },
  @{
    title = "Timeline activités récentes"
    desc  = @"
Cette carte spécifie la timeline d'activités affichée sur le dashboard : connexions récentes, créations/éditions de tickets, attributions d'équipements, changements de licences (Admin), documents ajoutés, notifications envoyées. Les événements affichés respectent le périmètre et la visibilité par rôle. La timeline prévoit des filtres de base (type, période), une pagination/chargement progressif et des libellés compréhensibles, avec liens vers les éléments d'origine.
"@
    dod   = @(
      "Schéma des événements et formatage des messages défini (/docs/dashboard/timeline-spec.md).",
      "Filtres de base (type/période) + pagination/chargement progressif spécifiés.",
      "RBAC appliqué: aucun événement hors périmètre affiché.",
      "États vide/erreur définis avec messages standards.",
      "Exemples rédigés pour chaque type d'événement avec liens de navigation.",
      "Validation PO/Tech sur pertinence et densité d'information."
    )
  }
)

# -------------------- Exécution --------------------
Write-Host "`n=== VÉRIFICATION DE L'AUTHENTIFICATION ===" -ForegroundColor Cyan
Write-Host "KEY: $($Key.Substring(0,8) + '...')" -ForegroundColor Gray
Write-Host "TOKEN: $($Token.Substring(0,8) + '...')" -ForegroundColor Gray

try {
  Write-Host "`nVérification du compte…" -ForegroundColor Cyan
  $me = Invoke-Trello "https://api.trello.com/1/members/me"
  Write-Host ("✅ Connecté : {0} (@{1})" -f $me.fullName, $me.username) -ForegroundColor Green
  
  Write-Host "`n=== CRÉATION DES RESSOURCES ===" -ForegroundColor Cyan
  
  # Utiliser l'ID de liste déjà récupéré ou le récupérer
  if ($selectedList.id) {
    $listId = $selectedList.id
    Write-Host ("✅ Liste: {0} ({1}) - ID récupéré" -f $TargetListName, $listId) -ForegroundColor Green
  } else {
    $listId = Get-OrCreate-ListId -BoardId $BoardId -ListName $TargetListName
    Write-Host ("✅ Liste: {0} ({1}) - ID créé/récupéré" -f $TargetListName, $listId) -ForegroundColor Green
  }
  
  # Utiliser l'ID de label déjà récupéré ou le créer
  if ($selectedLabel -and $selectedLabel.id) {
    $labelId = $selectedLabel.id
    Write-Host ("✅ Label: {0} ({1}) - ID récupéré" -f $LabelName, $labelId) -ForegroundColor Green
  } else {
    $labelId = Get-OrCreate-LabelId -BoardId $BoardId -Name $LabelName -Color $LabelColor
    if ($LabelName) { Write-Host ("✅ Label: {0} ({1}) couleur={2} - ID créé" -f $LabelName, $labelId, $LabelColor) -ForegroundColor Green } else { Write-Host "Aucun label spécifié" -ForegroundColor Gray }
  }
  
  Write-Host "`n=== CRÉATION DES CARTES ===" -ForegroundColor Cyan
  $created=@(); $errors=@(); $i=0; $n=$Cards.Count
  foreach ($c in $Cards) {
    $i++
    Write-Host ("[{0}/{1}] {2}" -f $i,$n,$c.title) -ForegroundColor Gray
    try {
      $card = New-TrelloCard -Title $c.title -Desc $c.desc -ListId $listId
      if ($labelId) {
        Add-LabelToCard -CardId $card.id -LabelId $labelId
      }
      Add-Checklist -CardId $card.id -ChecklistName $ChecklistName -Items $c.dod
      $created += [PSCustomObject]@{ Title=$c.title; Url=$card.shortUrl }
      Write-Host "  ✅ Carte créée" -ForegroundColor Green
    } catch {
      $errors  += [PSCustomObject]@{ Title=$c.title; Error=$_.ToString() }
      Write-Warning "  ❌ Erreur: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds $SleepBetween
  }
  
  Write-Host "`n=== RÉCAP ===" -ForegroundColor Cyan
  Write-Host ("✅ Créées: {0} | ❌ Erreurs: {1}" -f $created.Count, $errors.Count) -ForegroundColor White
  
  if ($created.Count -gt 0) {
    Write-Host "`n--- CARTES CRÉÉES ---" -ForegroundColor Green
    $created | Format-Table -AutoSize Title, Url
  }
  
  if ($errors.Count -gt 0) {
    Write-Host "`n--- ERREURS ---" -ForegroundColor Red
    $errors | Format-Table -AutoSize Title, Error
  }
  
  # Sauvegarder la configuration du board
  $saveBoardConfig = Read-Host "`nSauvegarder la configuration de ce board pour la prochaine fois ? (O/n)"
  if ($saveBoardConfig -eq "" -or $saveBoardConfig -eq "O" -or $saveBoardConfig -eq "o") {
    Save-BoardConfig -BoardUrl $BoardUrl -ListName $TargetListName -LabelName $LabelName -LabelColor $LabelColor
  }
  
  Write-Host "`n🎉 Script terminé avec succès !" -ForegroundColor Green
  Write-Host "Appuyez sur Entrée pour continuer..." -ForegroundColor Cyan
  Read-Host
  
} catch {
  Write-Host "`n❌ ERREUR CRITIQUE : $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "`nVérifiez que :" -ForegroundColor Yellow
  Write-Host "1. Votre KEY Trello est correcte" -ForegroundColor Yellow
  Write-Host "2. Votre TOKEN Trello est correcte" -ForegroundColor Yellow
  Write-Host "3. Vous avez accès au board spécifié" -ForegroundColor Yellow
  Write-Host "4. Votre connexion internet fonctionne" -ForegroundColor Yellow
  
  # Ne pas fermer PowerShell ISE, juste afficher l'erreur
  Write-Host "`nAppuyez sur Entrée pour continuer..." -ForegroundColor Cyan
  Read-Host
}
