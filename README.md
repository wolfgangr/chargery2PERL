## chargery2PERL
### Read from Chargery BMS port COM3 to monitor battery status
developped with Chargery BMS24T  

inspired by   
https://github.com/Tobi177/venus-chargerybms
  

format of chargery data export:  
https://github.com/Tobi177/venus-chargerybms/tree/master/docs
  

Hardware considerations and configuration clues:  
https://github.com/Tobi177/venus-chargerybms/issues/5
  
### Disclaimer:  
early testing stage -   
does not even work for me -  
never use for any serious work!  
Expect VERY nasty things to happen ;-)

### whats in
    *.rrd 
some rrd round robin databases  
  
    create*rrd.sh
    metacreate*.pl 
skripts to reproducibly produce them, only called at setup  
in a 2-step approach: `*.pl -> *.sh -> *.rrd`  
so we can find clues regarding rrd structure in the  `*.sh`  
  
 

    ../dev_chargery -> /dev/serial/by-path/foo_bar_whatever    
link to persistent location of USB-Dongle  
hope `/dev/serial/by-path/` allows us to avoid udev acrobatics  

 
    setstty-RS485.sh  
set terminal parameters for the USB-serial adapter where data comes in  
  
    update.pl  
do the most part of real work:
* read from data line
* parse chargery data
* write to rrd


[]()
  
 
    rrd2csv.pl
    rrdtest.pl
    rrdtest.sh
some helper stuff for hands on retrieval, debugging and the watchdog

    watchdog.sh  
cron script to check if rrd update is working  
good idea to be called every 5 min or so  
  
    create_tables.*  
some database structure generation hacks  

    login_sh_notsecret  
    secret_pwd.template  
    db_cred_template.pli  
anonymized versions of mysql credential vaults and command line login helpers    
  
    sync-chargery-rrd-to-SQL.sh  
cron'able database upload skript
syncs rrd data to a mysql  
  
  
---------  
last edit: 2020-12-31 v0.26
