# Scripts d'installation Veyon pour le collège

Scripts Windows (`.bat`) pour installer [Veyon](https://veyon.io), un logiciel libre et gratuit qui permet de superviser les ordinateurs des élèves. Avec Veyon, on peut voir les écrans, les verrouiller, présenter son écran, allumer ou éteindre les postes, etc.

> **Source** : ces scripts sont adaptés du kit publié par **Julien Delmas** dans l'article
> [« Veyon, l'application libre et gratuite de supervision des ordinateurs des élèves »](https://blog.juliendelmas.fr/?veyon-l-application-libre-et-gratuite-de-supervision-des-ordinateurs-des-eleves)
> (blog.juliendelmas.fr, mai 2022). Merci à lui.
>
> **Ajouts par rapport au kit d'origine** : nom des postes dans Veyon donné automatiquement (`SALLE-PC01`, `SALLE-PC02`…), import automatique des postes sur le poste prof, vérification des droits administrateur, attente de la fin de l'installation, journal par poste, écran vert ou rouge selon le résultat.

Une documentation complète, prête à imprimer, se trouve dans [`Documentation_Veyon.pdf`](Documentation_Veyon.pdf).

---

## Contenu

| Fichier | Rôle |
|---|---|
| `install_veyon_eleves.bat` | Installe Veyon **sans** la console Master et copie la **clé publique**. Nomme le poste dans Veyon. |
| `install_veyon_profs.bat` | Installe Veyon **avec** la console Master et copie la **clé privée**. |
| `importer_postes_veyon.bat` | À lancer sur le poste prof : importe la liste des postes (`postes.csv`) dans Veyon. |
| `veyon-setup.exe` | Programme d'installation de Veyon (64 bits). |
| `config/config.json` | Configuration appliquée à l'installation : authentification par clés. |
| `config/cles_eleves/` | Clé **publique**, pour les postes élèves. |
| `config/cles_profs/` | Clé publique et clé **privée**, pour les postes profs. La clé privée **n'est pas dans ce dépôt** (voir plus bas). |

Fichiers créés pendant l'utilisation, eux aussi absents du dépôt : `postes.csv` (la liste des postes) et `logs\NOM-DU-PC.log` (un journal par poste).

---

## Les clés : à lire avant tout

Veyon utilise une **paire de clés** :

- **La clé privée** reste sur les postes profs. C'est elle qui donne le droit de **voir et de contrôler** les postes élèves.
- **La clé publique** est copiée sur chaque poste élève. Elle permet au poste élève de vérifier que celui qui se connecte possède bien la clé privée qui va avec. On peut la diffuser sans risque.

> ⚠️ **Qui possède la clé privée peut voir et contrôler tous les postes élèves**, depuis n'importe quel PC branché sur le réseau du collège.

### Règles de sécurité

1. **Créez votre propre paire de clés.** Les clés du kit d'origine sont celles de son auteur, et toutes les personnes qui ont téléchargé le kit ont la même. Ne les utilisez pas en production.
2. **Ne publiez jamais la clé privée.** Elle est exclue de ce dépôt par `.gitignore` (`config/cles_profs/keys/private/`). Ne la mettez ni sur GitHub, ni dans un ENT, ni dans un mail.
3. **Rangez la clé USB d'installation** des postes profs dans un endroit sûr, ou utilisez une clé USB réservée aux postes profs.
4. **Ne lancez jamais `install_veyon_profs.bat` sur un poste élève.**
5. **En cas de fuite** (clé USB perdue, clé privée publiée) : créez une nouvelle paire de clés et réinstallez tous les postes. L'ancienne clé ne fonctionnera plus dès que les postes élèves auront la nouvelle clé publique.

### Créer sa paire de clés (à faire une seule fois)

Sur un PC où Veyon est installé, lancez une invite de commandes **en tant qu'administrateur**.

1. Créez la paire de clés sous le nom `profs`. Ce nom doit rester exactement `profs`, car c'est le nom des dossiers utilisés par les scripts :

   ```bat
   "C:\Program Files\Veyon\veyon-cli.exe" authkeys create profs
   ```

   On peut aussi passer par **Veyon Configurator** → *Authentification par clé* → *Créer une paire de clés*.

2. Les deux clés sont créées dans :
   - `C:\ProgramData\Veyon\keys\private\profs\key` (clé privée)
   - `C:\ProgramData\Veyon\keys\public\profs\key` (clé publique)

3. Copiez-les dans le dossier des scripts :

   | Copier… | …vers |
   |---|---|
   | `C:\ProgramData\Veyon\keys\private\profs\key` | `config\cles_profs\keys\private\profs\key` |
   | `C:\ProgramData\Veyon\keys\public\profs\key` | `config\cles_profs\keys\public\profs\key` |
   | `C:\ProgramData\Veyon\keys\public\profs\key` | `config\cles_eleves\keys\public\profs\key` |

4. Si vous utilisez ce dépôt Git, commitez **uniquement** les deux clés publiques. Le `.gitignore` empêche la clé privée d'y entrer par erreur.

> Si vous récupérez ce dépôt depuis GitHub, le dossier `config\cles_profs\keys\private\` n'existe pas. Créez votre paire de clés comme indiqué ci-dessus **avant** d'installer les postes. Sans la clé privée, le poste prof s'installe, mais Veyon Master ne pourra pas se connecter aux postes élèves.

---

## Utilisation

Lancez chaque script par **clic droit → *Exécuter en tant qu'administrateur***, depuis le dossier qui contient les scripts (une clé USB, par exemple).

### 1. Postes élèves : `install_veyon_eleves.bat`

1. Lancez le script en administrateur.
2. **Au premier poste seulement**, le script demande la salle (par exemple `S12`). Les caractères autorisés sont les lettres sans accent, les chiffres, l'espace, le point, `-` et `_`.
3. Le poste reçoit automatiquement un nom dans Veyon : `S12-PC01`, puis `S12-PC02` au poste suivant, et ainsi de suite. **Le nom Windows de l'ordinateur ne change pas.**
4. Un écran **vert** confirme que tout s'est bien passé. Un écran **rouge** indique l'étape qui a échoué et l'emplacement du journal.

Fonctionnement de la numérotation :

- Le script reprend la salle de la dernière ligne de `postes.csv` et prend le numéro suivant le plus grand déjà utilisé.
- Si vous réinstallez un poste déjà présent dans le CSV, il garde son nom.
- **Pour changer de salle**, utilisez un dossier séparé (avec son propre `postes.csv`) ou renommez `postes.csv` avant de passer à la salle suivante.

### 2. Postes profs : `install_veyon_profs.bat`

1. Vérifiez que la clé privée est bien dans `config\cles_profs\keys\private\profs\key`.
2. Lancez le script en administrateur.
3. Écran vert : Veyon Master est installé.

### 3. Liste des postes sur le poste prof : `importer_postes_veyon.bat`

1. Une fois les postes élèves installés, branchez la clé USB, avec son `postes.csv`, sur le poste prof.
2. Lancez `importer_postes_veyon.bat` en administrateur.
3. Vérifiez la liste affichée, puis confirmez avec `O`.
4. Ouvrez **Veyon Master** et cochez la salle : les postes apparaissent avec leur nom (`S12-PC01`…).

> ⚠️ L'import **remplace** la liste des salles et des postes qui existe déjà sur ce poste prof. S'il y a plusieurs postes profs, lancez l'import sur chacun d'eux.

---

## Dépannage

| Problème | Piste |
|---|---|
| Écran rouge « Ce script doit être lancé en tant qu'administrateur » | Clic droit → *Exécuter en tant qu'administrateur*. |
| Écran rouge « ECHEC : … » | Ouvrez le journal `logs\NOM-DU-PC.log` sur la clé USB. |
| Veyon Master n'affiche pas un écran (accès refusé) | La clé publique du poste élève ne va pas avec la clé privée du poste prof. Recopiez les clés, ou réimportez-les dans Veyon Configurator. |
| Un poste reste injoignable | Faites `ping NOM-DU-PC` depuis le poste prof. Sans serveur DNS, utilisez l'adresse IP du poste (IP fixe conseillée). |
| Allumer les postes à distance | Il faut l'adresse MAC du poste dans Veyon et le *Wake on LAN* activé dans le BIOS. |

---

## Crédits

- Kit et procédure d'origine : **Julien Delmas**, [blog.juliendelmas.fr](https://blog.juliendelmas.fr/?veyon-l-application-libre-et-gratuite-de-supervision-des-ordinateurs-des-eleves).
- Veyon : [veyon.io](https://veyon.io), logiciel libre sous licence GPL v2.
