
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

	U_nom           => 2.3,

	U_min_gentle	=> 2.0,
	U_min_moderate	=> 1.9,
	U_min_stop	=> 1.8,
	U_min_cutoff    => 1.5,

) ;

our @warn_levels = qw( nom     gentle   moderate stop      cutoff) ;
our @warn_colors = qw( 00cc00  aacc00   ffff00   ff6600    ff0000  );


1;