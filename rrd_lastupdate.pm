# returns a status hash
#
# %rrdstatus = rrd_lastupdate ( $rrdfile, [ $gracetime ]) 
sub rrd_lastupdate {
        my $rrdfile = shift ;
        my $gracetime = shift || 60 ;

        my %rvh = ( rrdfile => $rrdfile , gracetime => $gracetime );

        my $now = $rvh{testtime} =  time();

	# we recieve a hashref  with all key-val pairs as printed at stdout by `rrdtool info`
	my $rrd_info  = RRDs::info ($rrdfile);
        # $rvh{rrd_info} = $rrd_info ; # for debug we want to know anything
        if (defined ($rvh{'rrd_err' } =  RRDs::error) ) {
                $rvh{'rrd_errstr' } = $rvh{'rrd_err' };
                return %rvh ;
        }
        $rvh{rrd_step} =  $$rrd_info{step};

        my $lastupdate =  $rvh{lastupdate} =  $$rrd_info{last_update}; # ah we can drop the first call
        my $lastupdate_obj = Time::Piece->new($lastupdate);
        my $now_obj = Time::Piece->new($now);
        $rvh{testime_hr} = $now_obj->date . ' - ' .  $now_obj->time ;
        $rvh{lastupdate_hr} = $lastupdate_obj->date . ' - ' .  $lastupdate_obj->time ;

        $rvh{OK} = ( ($rvh{passed} = $now - $lastupdate ) <= $gracetime );

	# map `ds[U01].index = 0`  to % ( label => index ) 
        my %ds_map = map {  /^ds\[(\S+)\]\.index$/  ?   ( $1 , $$rrd_info{ $_}   ) : ( )  } sort keys %$rrd_info ;
        $rvh{ ds_map } = \%ds_map ;

        # tag array - sorted by index
        my @ds_tags =  sort  {  $ds_map{ $a } <=> $ds_map{ $b }   }   keys %ds_map;
        $rvh{ ds_tags } = \@ds_tags ;

        # last updated values as array
        my @ds_last = map {  $$rrd_info{  sprintf 'ds[%s].last_ds', $_   }    } @ds_tags ;
        $rvh{ ds_last  } = \@ds_last ;

        my @ds_s_unkn = map {  $$rrd_info{  sprintf 'ds[%s].unknown_sec', $_   }    } @ds_tags ;
        $rvh{ds_s_unkn} = \@ds_s_unkn ;

        $rvh{'rrd_errstr' } ='-' ;
        return %rvh ;

}

1;
