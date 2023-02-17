
PIX=\
mulle-sde-overview.svg \
walk-flat.svg \
walk-in-order.svg \
walk-post-order.svg \
walk-pre-order.svg \
walk-breadth-first.svg \
visit.svg

%.svg: %.dot
	dot -Tsvg -o $*.svg $<

all: $(PIX)
