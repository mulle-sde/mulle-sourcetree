
PIX=\
walk-flat.png \
walk-post-order.png \
walk-pre-order.png \
walk-breadth-first.png \
visit.png

%.png: %.dot
	dot -Tpng -o $*.png $<

all: $(PIX)
