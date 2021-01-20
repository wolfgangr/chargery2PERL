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
  
 
## chargery quirks

It looks like data is only sent when the chargery LCD control unit is on.  
There is a config settin for LCD illumination off, but it seems to be ignored.  
I just set it manually off, since even large batteries once upon a time get exhausted by tiny current.  
Well, looks like that's the price for data, at least at the moment?  

 
---------  
last edit: 2020-12-31 v0.26

version history:

```
v0.01           parses first 3 bytes
v0.02           correct splitting of data array
v0.03           checksum test
v0.04           process 56 and 57 - tested
v0.10           looks like test is r^Cghly completed
v0.11           live read from real tty line
v0.12           rrd update command 57 successfully tested
v0.13           first cont'd test run cmd 56 & 57
v0.14           debug system cleanup OK
v0.20           rrd2csv reasonably working
v0.21           cleanup file system etc
v0.22           add rrdtest basic watchdog utils
v0.23           add database generation scripts
v0.24           add database sync scripts
v0.25           add time zone handler to csv-exporter and resolved git detached head
v0.26           added cron'able watchdog
```

# ToDo per 2021-01-20:
* OK - pull render into project tree
* include status page and status API for BMS feed to infini
* fix current shunt issue
* switch from cron watchdog to systemd
* production test
 
