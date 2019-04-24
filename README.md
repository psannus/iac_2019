# Infrastructure as Code.

Siin tutvustame  [Hashicorp Terraform](https://www.terraform.io/) ja [Ansible](http://docs.ansible.com/ansible/latest/index.html) tööriistu, mille abil saab infrastruktuuri VCS-s hoida. Kogu keskkond on äärmiselt lihtsustatud ja ei pruugi parimaid praktikaid kasutada. Terraformi näited tehakse [AWS](https://console.aws.amazon.com/console/home) abil, seega on tarvilik Amazoni Starter konto (Educate account ei piisa).

Ansible ülesanne on lahendatav lokaalses masinas.

## Töö käik

1. Forkige käesolev repositoorium
2. Kui olete ülesande lahendanud, siis committige-pushige kood ja lisage oma repo URL ained.ttu.ee ülesande juurde
3. Ansible ülesanne on praksiülesanne, Terraform on vabatahtlik neile, kes soovivad teemat paremini tunda.


### Terraform (vabatahtlik)
Terraform on IaC platvorm, mis võimaldab kasutada definitsioonides nii JSON, kui ka enda formaati. Näited on Terraformi formaadis. Terraform oskab ressursse hallata läbi mitmete pilveteenusepakkujate API-de, siin kasutame Amazon Web Serviceid.
* [Downloadi](https://www.terraform.io/downloads.html) ja paki lahti Terraform oma platvormile. Tegemist on ühe käivitatava failiga, mis peaks olema kataloogis, mis sisaldub süsteemses PATH-s. Eraldi installeerimist vaja ei ole.
* Logi sisse oma [AWS konsooli](https://console.aws.amazon.com/console/home) ja loo _Access Key_. Selleks mine _Account settings_ => _Account ID_ => _My security credentials_ => _Create New Access Key_. Pane saadud  "Access Key ID" ja "Secret Access Key" väärtused kirja. Need tuleks panna `~/.aws/credentials` faili oma sektsiooni, näit
  ```
  [minu_aws]
  aws_access_key_id = 123456789ABCDEFGH
  aws_secret_access_key = 123456789ABCDEFGH
  ```
  Kui vaja, siis loo see kataloog ja fail. Windowsis näit käsurealt `mkdir` käsu abil.
 
* Seadista `AWS_PROFILE` keskkonnamuutuja (environment variable):
    ```
    AWS_PROFILE="minu_aws"
    ``` 

_AWS Image_-te ise tegemiseks on oma tööriistad, näiteks [Packer](https://www.packer.io/), aga siin näites võtame aluseks valmis _Amazon Linux image_.

* Näed repos tf kataloogis faili `main.tf`, kus on kirjas üldised seadistused - _AWS_ regioon  ja lubatud _account_id_'d. Account id ei ole vajalik, aga hoiab ära kogemata vale keskkonna kasutamisel juhtuda võivad õnnetused. Selle leiad AWS konsoolist _My Account_ alt _Account Settings_ sektsioonist. Muuda see `main.tf` failis ära.

* Teine fail tf kataloogis on `ec2-appserver.tf`, mis sisaldab rakenduse serveri seadistusi. EC2 tähendab lahti kirjutatult Elastic Compute Cloud ja on AWS tavaserveri tüüp. `ec2-appserver.tf` failis:
  - seadistatakse turvareeglid `aws_security_group`, mis võimaldavad kogu maailmal ligipääsu ssh pordile ja rakenduse pordile 80. Lisaks saab EC2 serverist ligipääsu kogu internetile.
  - Lisaks määratakse seal avalik võti `aws_key_pair`, millega pääseb üle ssh serverile ligi. Hetkel on seal kellegi [kowalski](http://madagascar.wikia.com/wiki/Kowalski) avalik võti. See tuleb asendada
   omaenda avaliku ssh võtmega. Kui Sul juhtumisi ei olegi ssh võtmeid, siis guugelda, kuidas neid oma platvormi peal genereerida ja kasutada. Terraformi võti peaks olema ilma passphrase-ta.
  - Järgnevaks defineeritakse EC2 instants `aws_instance` Amazon Linux 2 Candidate _image_-ga, mis kasutab eelnevalt defineeritud `aws_key_pair` ja `security_group` ressursse.
  - Peale loomist  `aws_instance` ka provisioneeritakse (seatakse üles, installeeritakse vajalik tarkvara), kohalikus masinas kirjutatakse loodud masina avalik IP aadress `ip_address.txt` faili ja `remote-exec` sektsioonis installeeritakse loodud serverisse üle ssh OpenJdk 8. Provisioneerimise ligipääsuks asenda _remote-exec_ sektsioonis privaatvõtme asukoht enda privaatvõtme (avalik võti sai sisestatud `aws_key_pair` sektsiooni) faili asukohaga.
* Nüüd käivita tf kataloogis `terraform init`. See laeb alla vajalikud Terraformi moodulid.
* `terraform plan` näitab, et mida käivitades tegema hakatakse, aga ei tee veel ühtegi tegevust.
* Kui kõik tundub plaanis sobivat, siis käivita `terraform apply` ja kirjuta yes, server peaks tekitatama ja seadistatama.

* EC2 serveril on vaikimisi ka avalik dünaamiline IP aadress, mis kirjutatakse faili `ip_address.txt`. Kui kõik õnnestus, siis peaksid ssh ja oma privaatvõtme abil sinna ligi pääsema. Näit:

  `# IP=$(cat ip_address.txt); ssh ec2-user@${IP}`

Lisaks tekkis nüüd tf kataloogi ka `terraform.tfstate` fail, mis sisaldab AWS viimast _state_-i nii nagu terraform seda teab. tfstate tuleks muudatuste tegemisel committida reposse ja seal peaks alati olema viimane versioon. Seega ei ole Terraformi repodes hea branchides terraformi tööle lasta.

Tekitasime Terraformi abil linux serveri, millel on Openjdk 8 ja dünaamiline avalik ip aadress.

Kuigi otsest tarvidust ei ole ja kõik saaks soovi korral ka terraformi abil ära teha, siis õppimise eesmärgil teeme järgmised sammud Ansible-nimelise tarkvara abil.
 
* NB! Peale töö lõpetamist ära unusta kirjutamast `terraform destroy`, et kõik terraformi poolt loodud ressursid ära kustutada. Kui tahad läbida ka järgmist sammu Ansible abil, siis ära destroy veel tee.



### Ansible (praksiülesanne)
Ansible on serverite provisioneerimise, konfiguratsioonihalduse ja CD platvorm, mis kasutab definitsioonides [YAML](http://yaml.org/) süntaksit. Serveritega ühendub ta üle ssh ja mingeid agente ei vaja. Windows ei ole kontrolliva hostina toetatud. Windowsi omanikud peaksid kasutama muud virtualiseeritud operatsioonisüsteemi. Lihtne lahendus on kasutada AWS EC2 serverit (kloonige repo sinna ja andke tuld). 

Ansible seob defineeritud ülesanded (taskid)  _play_-deks. _Playbook_ kirjeldab ühte või mitut _play_-d. Siin on kirjeldatud lihtne _playbook_ Ansible abil sinu Spring Boot rakenduse _deployment_-iks. 

* Installeeri oma platvormile Ansible _control-host_ nagu kirjeldatud [siin](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-the-control-machine) Kui installeerid Pythoni kaudu, siis tasub kindlasti luua [Python virtual environment](https://virtualenvwrapper.readthedocs.io/en/latest/install.html), et mitte süsteemseid pythoni teeke risustada ja konflikte ära hoida.

* Muuda ansible kataloogis ära `ansible_ssh_host` väärtus failis `inventory.ini`. `ansible_ssh_host` on remote provisioneeritava ip aadress (mitte selle masina aadress, kus te ansiblet installeerisite), EC2 serveri puhul leiad selle IP oma aws konsoolist. Ehk siis see on selle masina IP, kus programm tööle hakkab.

Kui lahendasid vabatahtliku osa, siis Terraformiga loodud serveri IP aadressi leiad `tf/ip_address.txt` failist. Inventory on grupeeritud kogum Ansible hostidest, mida saab laadida ka dünaamiliselt, aga siin teeme seda staatiliselt.

* Kui kõik on õigesti seadistatud, siis ansible kataloogis `ansible myapp-server -m ping` käivitades peaks rohelise `SUCCESS` vastuse saama.

* Buildi oma projektist käivitatav kõikide sõltuvustega JAR. Käivitatav JAR on Spring Boot võimekus, mis kasutab asjaolu, et shell script alustab lugemist faili algusest, aga java jar faili lugemist lõpust. Rohkem on sellest kirjutatud (siin)[https://docs.spring.io/spring-boot/docs/current/reference/html/deployment-install.html]. Kui kasutasid start.spring.io projekti initsialiseerijat ja gradle build tooli, siis aitab sellest, kui lisad oma build.gradle faili järgmised read:
    ```
    bootJar {
        launchScript()
    }
    ```
    ning buildid projekt käsuga `gradlew bootJar`. `build` kataloogi tekkinud jar fail peaks olema nüüd iseseisvalt käivitatav. Kui see samm ei õnnestu, siis käivitatav demo jar fail on ka siin repos ansible failide kataloogis.

* Kes lisatud demo JAR-iga piirdub, see võib järgmise sammu juurde liikuda. Kopeeri build package ehk eelmises sammus saadud JAR fail `ansible/playbooks/files/var/myapp` kataloogi.

* Käivita Ansible playbook rakenduse _deploymiseks_ käsuga `ansible-playbook playbooks/deploy-myapp.yml`. Ansible küsib jar faili täpselt nime, selle võib copy-pasteda.

* Kui Ansible _deployment_ on edukalt lõpetanud, siis võid brauseriga minna oma rakenduse serveri IP aadressile pordile 8080 ja pääsed rakendusele ligi.


