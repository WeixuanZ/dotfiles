set encoding utf8

set samples 2000

# See https://github.com/Gnuplotting/gnuplot-palettes
# line styles
set style line 1 lt 1 lw 1.5 lc rgb '#D53E4F' # red
set style line 2 lt 1 lw 1.5 lc rgb '#F46D43' # orange
set style line 3 lt 1 lw 1.5 lc rgb '#FDAE61' # pale orange
set style line 4 lt 1 lw 1.5 lc rgb '#FEE08B' # pale yellow-orange
set style line 5 lt 1 lw 1.5 lc rgb '#E6F598' # pale yellow-green
set style line 6 lt 1 lw 1.5 lc rgb '#ABDDA4' # pale green
set style line 7 lt 1 lw 1.5 lc rgb '#66C2A5' # green
set style line 8 lt 1 lw 1.5 lc rgb '#3288BD' # blue

# palette
set palette defined ( 0 '#D53E4F',\
                      1 '#F46D43',\
                      2 '#FDAE61',\
                      3 '#FEE08B',\
                      4 '#E6F598',\
                      5 '#ABDDA4',\
                      6 '#66C2A5',\
                      7 '#3288BD' )


# axis
set style line 101 lc rgb '#808080' lt 1 lw 1
set border 3 front ls 101
set tics nomirror out scale 0.75
set format '%g'


# grid
#set style line 102 lc rgb '#d6d7d9' lt 0 lw 1
#set grid back ls 102