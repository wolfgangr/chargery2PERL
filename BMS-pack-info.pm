
our %pack_info = (
	n_serial 	=> 22,
	n_parallel 	=> 10,
	cell_tech	=> 'LTO',
	cell_type	=> 'Yinlong LTO66160H',

	C_nom		=> 40,
	I_nom		=> 40,
	I_max_chg	=> 400,
	I_max_dischg    => 400,


	U_max_cutoff	=> 2.9,
	U_max_stop	=> 2.8,
	U_max_moderate	=> 2.7,
	U_max_gentle    => 2.6,
	U_max_info	=> 2.5,

	U_nom           => 2.3,

	U_min_info 	=> 2.1,
	U_min_gentle	=> 2.0,
	U_min_moderate	=> 1.9,
	U_min_stop	=> 1.8,
	U_min_cutoff    => 1.5,

) ;

our @warn_levels  = qw( nom     info     gentle   moderate  stop     cutoff) ;
our @warn_col_lo  = qw( cccc8e  d8d844   ffff00   ff6600    ff0000   ff0088 );
our @warn_col_hi  = qw( aacc8e  aadd77   44ff33   00cccc    0044ff   8800ff ) ;



1;
